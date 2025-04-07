```solidity
/**
 * @title Dynamic NFT Ecosystem with Advanced Features
 * @author Bard (AI Assistant)
 * @dev This contract implements a Dynamic NFT ecosystem with various advanced features,
 * including dynamic metadata, on-chain governance, staking, renting, fractionalization,
 * and more. It aims to be creative and trendy, avoiding duplication of common open-source contracts.
 *
 * **Outline:**
 *
 * 1. **NFT Management:**
 *    - Minting Dynamic NFTs
 *    - Transferring NFTs
 *    - Burning NFTs
 *    - Getting NFT Metadata URI
 *    - Setting Base Metadata URI
 *
 * 2. **Dynamic NFT Properties:**
 *    - Updating NFT Property (Generic)
 *    - Setting Dynamic Property Resolver Contract
 *    - Resolving Dynamic Metadata On-Chain
 *
 * 3. **Ecosystem Governance:**
 *    - Proposing New Features/Changes
 *    - Voting on Proposals
 *    - Executing Approved Proposals
 *    - Setting Quorum for Proposals
 *    - Setting Voting Period
 *
 * 4. **Marketplace & Trading:**
 *    - Listing NFT for Sale
 *    - Buying NFT
 *    - Canceling NFT Listing
 *    - Listing NFT for Auction
 *    - Bidding on Auction
 *    - Ending Auction
 *
 * 5. **NFT Utility & Staking:**
 *    - Staking NFT for Rewards
 *    - Unstaking NFT
 *    - Setting Staking Reward Rate
 *    - Claiming Staking Rewards
 *
 * 6. **Advanced NFT Features:**
 *    - Renting NFT
 *    - Ending NFT Rental
 *    - Fractionalizing NFT (Basic Example - Requires further development for practical use)
 *    - Merging Fractionalized NFTs (Basic Example)
 *
 * 7. **Admin & Management:**
 *    - Pausing Contract Functionality
 *    - Unpausing Contract Functionality
 *    - Withdrawing Contract Balance
 *    - Setting Fee for Marketplace
 *    - Setting Fee Recipient
 *
 * **Function Summary:**
 *
 * **NFT Management:**
 * - `mintDynamicNFT(address _to, string memory _baseMetadataURI)`: Mints a new Dynamic NFT to the specified address.
 * - `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another.
 * - `burnNFT(uint256 _tokenId)`: Burns (destroys) an NFT.
 * - `tokenURI(uint256 _tokenId)`: Returns the metadata URI for a given NFT ID.
 * - `setBaseMetadataURI(string memory _baseURI)`: Sets the base URI used for generating NFT metadata.
 *
 * **Dynamic NFT Properties:**
 * - `updateNFTProperty(uint256 _tokenId, string memory _propertyName, string memory _propertyValue)`: Updates a generic property of an NFT.
 * - `setDynamicPropertyResolver(address _resolverAddress)`: Sets the address of a contract that can dynamically resolve NFT properties.
 * - `resolveDynamicMetadata(uint256 _tokenId)`: Fetches and potentially updates dynamic metadata for an NFT using the resolver contract.
 *
 * **Ecosystem Governance:**
 * - `createGovernanceProposal(string memory _description, bytes memory _calldata)`: Creates a new governance proposal.
 * - `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to vote on a governance proposal.
 * - `executeProposal(uint256 _proposalId)`: Executes an approved governance proposal.
 * - `setProposalQuorum(uint256 _quorum)`: Sets the minimum percentage of votes required for proposal approval.
 * - `setVotingPeriod(uint256 _periodInBlocks)`: Sets the voting period for proposals in blocks.
 *
 * **Marketplace & Trading:**
 * - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale at a fixed price.
 * - `buyNFT(uint256 _listingId)`: Allows buying an NFT listed for sale.
 * - `cancelNFTSaleListing(uint256 _listingId)`: Cancels an NFT sale listing.
 * - `listNFTForAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration)`: Lists an NFT for auction with a starting bid and duration.
 * - `bidOnAuction(uint256 _auctionId)`: Allows users to bid on an active auction.
 * - `endAuction(uint256 _auctionId)`: Ends an auction and transfers the NFT to the highest bidder.
 *
 * **NFT Utility & Staking:**
 * - `stakeNFTForRewards(uint256 _tokenId)`: Stakes an NFT to earn rewards.
 * - `unstakeNFT(uint256 _tokenId)`: Unstakes an NFT.
 * - `setStakingRewardRate(uint256 _rewardRatePerBlock)`: Sets the reward rate for staking NFTs.
 * - `claimStakingRewards(uint256 _tokenId)`: Claims accumulated staking rewards for an NFT.
 *
 * **Advanced NFT Features:**
 * - `rentNFT(uint256 _tokenId, uint256 _rentalDuration)`: Allows renting an NFT for a specified duration.
 * - `endNFTRental(uint256 _tokenId)`: Ends an active NFT rental.
 * - `fractionalizeNFT(uint256 _tokenId, uint256 _numberOfFractions)`: (Basic) Fractionalizes an NFT into a given number of fungible tokens.
 * - `mergeFractionalizedNFTs(uint256 _originalTokenId)`: (Basic) Merges fractionalized tokens back into the original NFT.
 *
 * **Admin & Management:**
 * - `pauseContract()`: Pauses most contract functionalities.
 * - `unpauseContract()`: Unpauses contract functionalities.
 * - `withdrawContractBalance()`: Allows the contract owner to withdraw ETH from the contract.
 * - `setMarketplaceFee(uint256 _feePercentage)`: Sets the marketplace fee percentage.
 * - `setFeeRecipient(address _recipient)`: Sets the address that receives marketplace fees.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Example for advanced feature

contract DynamicNFTEcosystem is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string public baseMetadataURI;
    address public dynamicPropertyResolver;
    uint256 public marketplaceFeePercentage = 2; // 2% default fee
    address public feeRecipient;

    // NFT Properties (Generic - can be extended)
    mapping(uint256 => mapping(string => string)) public nftProperties;

    // Marketplace Listings
    struct SaleListing {
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }
    mapping(uint256 => SaleListing) public saleListings; // listingId => SaleListing
    Counters.Counter private _saleListingCounter;

    // Auctions
    struct Auction {
        uint256 tokenId;
        uint256 startingBid;
        uint256 endTime;
        address payable highestBidder;
        uint256 highestBid;
        bool isActive;
    }
    mapping(uint256 => Auction) public auctions; // auctionId => Auction
    Counters.Counter private _auctionCounter;

    // Staking
    mapping(uint256 => uint256) public nftStakeStartTime; // tokenId => startTime
    uint256 public stakingRewardRatePerBlock = 1; // Example: 1 reward unit per block
    mapping(address => uint256) public stakingRewardsBalance; // user => rewards balance

    // Renting
    struct Rental {
        uint256 tokenId;
        address renter;
        uint256 rentalEndTime;
        bool isActive;
    }
    mapping(uint256 => Rental) public nftRentals; // tokenId => Rental

    // Fractionalization (Basic - Needs further development for practical use)
    mapping(uint256 => address) public fractionalizedNFTContract; // original tokenId => fractional token contract address

    // Governance
    struct Proposal {
        string description;
        bytes calldataData;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalCounter;
    uint256 public proposalQuorumPercentage = 50; // 50% default quorum
    uint256 public votingPeriodBlocks = 100; // 100 blocks default voting period
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voterAddress => voted

    event NFTMinted(uint256 tokenId, address to);
    event NFTPropertyUpdated(uint256 tokenId, string propertyName, string propertyValue);
    event NFTSaleListed(uint256 listingId, uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 listingId, uint256 tokenId, uint256 price, address buyer);
    event NFTAuctionListed(uint256 auctionId, uint256 tokenId, uint256 startingBid, uint256 endTime, address seller);
    event AuctionBidPlaced(uint256 auctionId, uint256 tokenId, uint256 bidAmount, address bidder);
    event AuctionEnded(uint256 auctionId, uint256 tokenId, address winner, uint256 winningBid);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event StakingRewardsClaimed(address user, uint256 amount);
    event NFTRented(uint256 tokenId, address renter, uint256 rentalEndTime);
    event NFTRentalEnded(uint256 tokenId, address renter);
    event NFTFractionalized(uint256 originalTokenId, address fractionalTokenContract, uint256 numberOfFractions);
    event NFTMerged(uint256 originalTokenId);
    event GovernanceProposalCreated(uint256 proposalId, string description);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);

    constructor(string memory _name, string memory _symbol, string memory _baseMetadataURI) ERC721(_name, _symbol) {
        baseMetadataURI = _baseMetadataURI;
        feeRecipient = owner(); // Default fee recipient is contract owner
    }

    modifier whenNotRented(uint256 _tokenId) {
        require(!nftRentals[_tokenId].isActive, "NFT is currently rented.");
        _;
    }

    modifier whenNotStaked(uint256 _tokenId) {
        require(nftStakeStartTime[_tokenId] == 0, "NFT is currently staked.");
        _;
    }

    modifier whenNotFractionalized(uint256 _tokenId) {
        require(fractionalizedNFTContract[_tokenId] == address(0), "NFT is fractionalized.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT.");
        _;
    }

    modifier validListing(uint256 _listingId) {
        require(saleListings[_listingId].isActive, "Listing is not active.");
        _;
    }

    modifier validAuction(uint256 _auctionId) {
        require(auctions[_auctionId].isActive, "Auction is not active.");
        require(block.timestamp < auctions[_auctionId].endTime, "Auction has ended.");
        _;
    }

    modifier auctionEnded(uint256 _auctionId) {
        require(!auctions[_auctionId].isActive, "Auction is still active.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].votingStartTime <= block.number && block.number <= proposals[_proposalId].votingEndTime, "Proposal voting is not active.");
        _;
    }

    modifier proposalExecutable(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        require(totalVotes > 0, "No votes cast yet."); // Avoid division by zero
        require((proposals[_proposalId].yesVotes * 100) / totalVotes >= proposalQuorumPercentage, "Proposal quorum not reached.");
        require(block.number > proposals[_proposalId].votingEndTime, "Voting period not ended.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Contract is not paused.");
        _;
    }

    /**
     * @dev Mints a new Dynamic NFT to the specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseMetadataURI Base URI to construct the NFT metadata URI.
     */
    function mintDynamicNFT(address _to, string memory _baseMetadataURI) public onlyOwner whenNotPaused {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_to, tokenId);
        setBaseMetadataURI(_baseMetadataURI); // Allow setting base URI per mint for flexibility
        emit NFTMinted(tokenId, _to);
    }

    /**
     * @dev Transfers an NFT from one address to another.
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        safeTransferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev Burns (destroys) an NFT.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 _tokenId) public onlyOwner whenNotPaused {
        _burn(_tokenId);
    }

    /**
     * @dev Returns the metadata URI for a given NFT ID.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist.");
        string memory baseURIValue = baseMetadataURI;
        return string(abi.encodePacked(baseURIValue, _tokenId.toString(), ".json"));
    }

    /**
     * @dev Sets the base URI used for generating NFT metadata.
     * @param _baseURI The new base URI.
     */
    function setBaseMetadataURI(string memory _baseURI) public onlyOwner whenNotPaused {
        baseMetadataURI = _baseURI;
    }

    /**
     * @dev Updates a generic property of an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _propertyName The name of the property to update.
     * @param _propertyValue The new value of the property.
     */
    function updateNFTProperty(uint256 _tokenId, string memory _propertyName, string memory _propertyValue) public onlyOwner whenNotPaused {
        nftProperties[_tokenId][_propertyName] = _propertyValue;
        emit NFTPropertyUpdated(_tokenId, _propertyName, _propertyValue);
    }

    /**
     * @dev Sets the address of a contract that can dynamically resolve NFT properties.
     * @param _resolverAddress The address of the dynamic property resolver contract.
     */
    function setDynamicPropertyResolver(address _resolverAddress) public onlyOwner whenNotPaused {
        dynamicPropertyResolver = _resolverAddress;
    }

    /**
     * @dev Fetches and potentially updates dynamic metadata for an NFT using the resolver contract.
     *      This is a placeholder and would require a more complex interface and logic for a real-world resolver.
     * @param _tokenId The ID of the NFT to resolve metadata for.
     */
    function resolveDynamicMetadata(uint256 _tokenId) public whenNotPaused {
        require(dynamicPropertyResolver != address(0), "Dynamic property resolver not set.");
        // In a real implementation, you would call a function on the `dynamicPropertyResolver` contract
        // to fetch or update metadata based on the `_tokenId`.
        // This is a simplified example and needs to be expanded based on the resolver contract's design.
        // Example (Conceptual - requires interface definition):
        // IDynamicMetadataResolver resolver = IDynamicMetadataResolver(dynamicPropertyResolver);
        // string memory dynamicMetadata = resolver.getDynamicMetadata(_tokenId);
        // ... process and potentially update metadata based on dynamicMetadata ...
    }

    /**
     * @dev Creates a new governance proposal.
     * @param _description A description of the proposal.
     * @param _calldata The calldata to execute if the proposal passes.
     */
    function createGovernanceProposal(string memory _description, bytes memory _calldata) public onlyOwner whenNotPaused {
        _proposalCounter.increment();
        uint256 proposalId = _proposalCounter.current();
        proposals[proposalId] = Proposal({
            description: _description,
            calldataData: _calldata,
            votingStartTime: block.number,
            votingEndTime: block.number + votingPeriodBlocks,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit GovernanceProposalCreated(proposalId, _description);
    }

    /**
     * @dev Allows users to vote on a governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to support the proposal, false to oppose.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused proposalActive(_proposalId) {
        require(!proposalVotes[_proposalId][_msgSender()], "Already voted on this proposal.");
        proposalVotes[_proposalId][_msgSender()] = true;
        if (_support) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ProposalVoted(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Executes an approved governance proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused proposalExecutable(_proposalId) {
        proposals[_proposalId].executed = true;
        (bool success, ) = address(this).call(proposals[_proposalId].calldataData);
        require(success, "Proposal execution failed.");
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Sets the minimum percentage of votes required for proposal approval.
     * @param _quorum The new quorum percentage (0-100).
     */
    function setProposalQuorum(uint256 _quorum) public onlyOwner whenNotPaused {
        require(_quorum <= 100, "Quorum must be between 0 and 100.");
        proposalQuorumPercentage = _quorum;
    }

    /**
     * @dev Sets the voting period for proposals in blocks.
     * @param _periodInBlocks The new voting period in blocks.
     */
    function setVotingPeriod(uint256 _periodInBlocks) public onlyOwner whenNotPaused {
        votingPeriodBlocks = _periodInBlocks;
    }

    /**
     * @dev Lists an NFT for sale at a fixed price.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price in wei.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) public whenNotPaused onlyNFTOwner(_tokenId) whenNotRented(_tokenId) whenNotStaked(_tokenId) whenNotFractionalized(_tokenId) {
        _saleListingCounter.increment();
        uint256 listingId = _saleListingCounter.current();
        _approve(address(this), _tokenId); // Approve contract to transfer NFT
        saleListings[listingId] = SaleListing({
            tokenId: _tokenId,
            price: _price,
            seller: _msgSender(),
            isActive: true
        });
        emit NFTSaleListed(listingId, _tokenId, _price, _msgSender());
    }

    /**
     * @dev Allows buying an NFT listed for sale.
     * @param _listingId The ID of the sale listing.
     */
    function buyNFT(uint256 _listingId) public payable whenNotPaused validListing(_listingId) {
        SaleListing storage listing = saleListings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds.");
        require(listing.seller != _msgSender(), "Cannot buy your own NFT.");

        listing.isActive = false;
        uint256 feeAmount = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = listing.price - feeAmount;

        payable(listing.seller).transfer(sellerPayout);
        payable(feeRecipient).transfer(feeAmount);
        transferNFT(listing.seller, _msgSender(), listing.tokenId);
        emit NFTBought(_listingId, listing.tokenId, listing.price, _msgSender());
    }

    /**
     * @dev Cancels an NFT sale listing.
     * @param _listingId The ID of the sale listing to cancel.
     */
    function cancelNFTSaleListing(uint256 _listingId) public whenNotPaused validListing(_listingId) {
        require(saleListings[_listingId].seller == _msgSender(), "Only seller can cancel listing.");
        saleListings[_listingId].isActive = false;
    }

    /**
     * @dev Lists an NFT for auction with a starting bid and duration.
     * @param _tokenId The ID of the NFT to auction.
     * @param _startingBid The starting bid price in wei.
     * @param _auctionDuration The duration of the auction in seconds.
     */
    function listNFTForAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) public whenNotPaused onlyNFTOwner(_tokenId) whenNotRented(_tokenId) whenNotStaked(_tokenId) whenNotFractionalized(_tokenId) {
        _auctionCounter.increment();
        uint256 auctionId = _auctionCounter.current();
        _approve(address(this), _tokenId); // Approve contract to transfer NFT
        auctions[auctionId] = Auction({
            tokenId: _tokenId,
            startingBid: _startingBid,
            endTime: block.timestamp + _auctionDuration,
            highestBidder: payable(address(0)),
            highestBid: 0,
            isActive: true
        });
        emit NFTAuctionListed(auctionId, _tokenId, _startingBid, block.timestamp + _auctionDuration, _msgSender());
    }

    /**
     * @dev Allows users to bid on an active auction.
     * @param _auctionId The ID of the auction to bid on.
     */
    function bidOnAuction(uint256 _auctionId) public payable whenNotPaused validAuction(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(msg.value > auction.highestBid, "Bid must be higher than current highest bid.");
        require(msg.value >= auction.startingBid, "Bid must be at least the starting bid.");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund previous highest bidder
        }
        auction.highestBidder = payable(_msgSender());
        auction.highestBid = msg.value;
        emit AuctionBidPlaced(_auctionId, auction.tokenId, msg.value, _msgSender());
    }

    /**
     * @dev Ends an auction and transfers the NFT to the highest bidder.
     * @param _auctionId The ID of the auction to end.
     */
    function endAuction(uint256 _auctionId) public whenNotPaused auctionEnded(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction is not active.");
        auction.isActive = false;

        address payable seller = payable(ownerOf(auction.tokenId)); // Seller is the current NFT owner
        uint256 feeAmount = (auction.highestBid * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = auction.highestBid - feeAmount;

        if (auction.highestBidder != address(0)) {
            transferNFT(seller, auction.highestBidder, auction.tokenId);
            seller.transfer(sellerPayout);
            payable(feeRecipient).transfer(feeAmount);
            emit AuctionEnded(_auctionId, auction.tokenId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids placed, return NFT to seller (current owner)
            transferFrom(address(this), seller, auction.tokenId); // Need to transfer back from contract to seller if no bids.
            emit AuctionEnded(_auctionId, auction.tokenId, address(0), 0); // Winner is address(0) if no bids
        }
    }

    /**
     * @dev Stakes an NFT to earn rewards.
     * @param _tokenId The ID of the NFT to stake.
     */
    function stakeNFTForRewards(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) whenNotRented(_tokenId) whenNotStaked(_tokenId) whenNotFractionalized(_tokenId) {
        require(nftStakeStartTime[_tokenId] == 0, "NFT is already staked.");
        _approve(address(this), _tokenId); // Approve contract to transfer NFT
        transferFrom(_msgSender(), address(this), _tokenId); // Transfer NFT to contract for staking
        nftStakeStartTime[_tokenId] = block.number;
        emit NFTStaked(_tokenId, _msgSender());
    }

    /**
     * @dev Unstakes an NFT.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) whenStaked(_tokenId) {
        uint256 rewards = calculateStakingRewards(_tokenId);
        stakingRewardsBalance[_msgSender()] += rewards;
        nftStakeStartTime[_tokenId] = 0;
        transferNFT(address(this), _msgSender(), _tokenId); // Transfer NFT back to owner
        emit NFTUnstaked(_tokenId, _msgSender());
    }

    modifier whenStaked(uint256 _tokenId) {
        require(nftStakeStartTime[_tokenId] > 0, "NFT is not staked.");
        _;
    }

    /**
     * @dev Calculates staking rewards for an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The amount of staking rewards earned.
     */
    function calculateStakingRewards(uint256 _tokenId) public view returns (uint256) {
        if (nftStakeStartTime[_tokenId] == 0) {
            return 0;
        }
        uint256 blocksStaked = block.number - nftStakeStartTime[_tokenId];
        return blocksStaked * stakingRewardRatePerBlock;
    }

    /**
     * @dev Sets the reward rate for staking NFTs.
     * @param _rewardRatePerBlock The new reward rate per block.
     */
    function setStakingRewardRate(uint256 _rewardRatePerBlock) public onlyOwner whenNotPaused {
        stakingRewardRatePerBlock = _rewardRatePerBlock;
    }

    /**
     * @dev Claims accumulated staking rewards for an NFT owner.
     * @param _tokenId An NFT owned by the caller (used for context, not directly used for reward calculation).
     */
    function claimStakingRewards(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) {
        uint256 rewardsToClaim = stakingRewardsBalance[_msgSender()];
        require(rewardsToClaim > 0, "No rewards to claim.");
        stakingRewardsBalance[_msgSender()] = 0; // Reset balance after claiming
        payable(_msgSender()).transfer(rewardsToClaim); // Transfer rewards (assuming rewards are in ETH for simplicity)
        emit StakingRewardsClaimed(_msgSender(), rewardsToClaim);
    }

    /**
     * @dev Allows renting an NFT for a specified duration.
     * @param _tokenId The ID of the NFT to rent.
     * @param _rentalDuration The rental duration in seconds.
     */
    function rentNFT(uint256 _tokenId, uint256 _rentalDuration) public whenNotPaused onlyNFTOwner(_tokenId) whenNotRented(_tokenId) whenNotStaked(_tokenId) whenNotFractionalized(_tokenId) {
        require(!nftRentals[_tokenId].isActive, "NFT is already rented.");
        nftRentals[_tokenId] = Rental({
            tokenId: _tokenId,
            renter: _msgSender(),
            rentalEndTime: block.timestamp + _rentalDuration,
            isActive: true
        });
        emit NFTRented(_tokenId, _msgSender(), block.timestamp + _rentalDuration);
    }

    /**
     * @dev Ends an active NFT rental. Can be called by renter or owner.
     * @param _tokenId The ID of the NFT rental to end.
     */
    function endNFTRental(uint256 _tokenId) public whenNotPaused {
        require(nftRentals[_tokenId].isActive, "NFT is not rented.");
        require(nftRentals[_tokenId].renter == _msgSender() || ownerOf(_tokenId) == _msgSender() || block.timestamp >= nftRentals[_tokenId].rentalEndTime, "Only renter, owner, or after rental end time.");
        nftRentals[_tokenId].isActive = false;
        emit NFTRentalEnded(_tokenId, nftRentals[_tokenId].renter);
    }

    /**
     * @dev (Basic Example) Fractionalizes an NFT into a given number of fungible tokens.
     *      This is a simplified example and would require a more robust fractionalization token contract for practical use.
     * @param _tokenId The ID of the NFT to fractionalize.
     * @param _numberOfFractions The number of fractional tokens to create.
     */
    function fractionalizeNFT(uint256 _tokenId, uint256 _numberOfFractions) public whenNotPaused onlyNFTOwner(_tokenId) whenNotRented(_tokenId) whenNotStaked(_tokenId) whenNotFractionalized(_tokenId) {
        require(_numberOfFractions > 0, "Number of fractions must be greater than zero.");
        require(fractionalizedNFTContract[_tokenId] == address(0), "NFT already fractionalized.");

        // In a real implementation, you would deploy a new ERC20-like fractional token contract
        // associated with this NFT. Here, we are skipping contract creation for simplicity.
        // For demonstration, we'll just store a placeholder address.
        address fractionalTokenAddress = address(this); // Using this contract address as a placeholder.
        fractionalizedNFTContract[_tokenId] = fractionalTokenAddress;

        // In a real implementation, you would mint `_numberOfFractions` tokens of the new fractional token contract
        // and distribute them to the NFT owner.
        // For demonstration, we are skipping token minting and distribution.

        _burn(_tokenId); // Burn the original NFT after fractionalization
        emit NFTFractionalized(_tokenId, fractionalTokenAddress, _numberOfFractions);
    }

    /**
     * @dev (Basic Example) Merges fractionalized tokens back into the original NFT.
     *      This is a simplified example and would require a more robust fractionalization token and logic.
     * @param _originalTokenId The ID of the original NFT that was fractionalized.
     */
    function mergeFractionalizedNFTs(uint256 _originalTokenId) public whenNotPaused {
        require(fractionalizedNFTContract[_originalTokenId] != address(0), "NFT is not fractionalized.");
        // In a real implementation, you would require the caller to burn a sufficient number of fractional tokens
        // from the associated fractional token contract.
        // For demonstration, we are skipping fractional token burning.

        // Mint a new NFT with the original token ID (assuming it's still available, or handle ID conflicts).
        _mint(_msgSender(), _originalTokenId);
        fractionalizedNFTContract[_originalTokenId] = address(0); // Reset fractionalization status
        emit NFTMerged(_originalTokenId);
    }

    /**
     * @dev Pauses most contract functionalities.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses contract functionalities.
     */
    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw ETH from the contract.
     */
    function withdrawContractBalance() public onlyOwner whenNotPaused {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Sets the marketplace fee percentage.
     * @param _feePercentage The new fee percentage (0-100).
     */
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100.");
        marketplaceFeePercentage = _feePercentage;
    }

    /**
     * @dev Sets the address that receives marketplace fees.
     * @param _recipient The address to receive fees.
     */
    function setFeeRecipient(address _recipient) public onlyOwner whenNotPaused {
        require(_recipient != address(0), "Recipient address cannot be zero address.");
        feeRecipient = _recipient;
    }

    // Override supportsInterface to declare ERC165 interface ID for dynamic metadata resolution (if needed)
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        // Example: If you define a custom interface for dynamic metadata resolver, you can add it here.
        // return interfaceId == type(IDynamicMetadataResolver).interfaceId || super.supportsInterface(interfaceId);
        return super.supportsInterface(interfaceId);
    }
}
```