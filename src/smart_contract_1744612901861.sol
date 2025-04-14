```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Evolving Traits
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace where NFTs can evolve and have
 *      various advanced features including dynamic traits, staking, governance,
 *      customizable royalties, and a decentralized auction system.
 *
 * **Outline and Function Summary:**
 *
 * **NFT Management:**
 *   1. `mintNFT(address _to, string memory _baseURI)`: Mints a new Dynamic NFT to the specified address.
 *   2. `setBaseMetadataURI(string memory _baseURI)`: Sets the base URI for NFT metadata.
 *   3. `tokenURI(uint256 _tokenId)`: Returns the URI for a specific NFT token.
 *   4. `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of an NFT. (Internal function, used by marketplace)
 *   5. `approveNFT(address _approved, uint256 _tokenId)`: Approves an address to operate on a specific NFT.
 *   6. `getApprovedNFT(uint256 _tokenId)`: Gets the approved address for a specific NFT.
 *   7. `setDynamicTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue)`: Sets a dynamic trait for an NFT.
 *   8. `getDynamicTrait(uint256 _tokenId, string memory _traitName)`: Retrieves a dynamic trait value for an NFT.
 *   9. `evolveNFT(uint256 _tokenId)`: Triggers the evolution of an NFT based on predefined conditions (example: time-based).
 *
 * **Marketplace Operations:**
 *  10. `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 *  11. `buyNFT(uint256 _listingId)`: Allows anyone to buy a listed NFT.
 *  12. `cancelNFTSale(uint256 _listingId)`: Allows the NFT owner to cancel a sale listing.
 *  13. `createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration)`: Creates a Dutch auction for an NFT.
 *  14. `bidOnAuction(uint256 _auctionId)`: Allows users to bid on an active auction.
 *  15. `settleAuction(uint256 _auctionId)`: Settles a completed auction and transfers NFT to the highest bidder.
 *  16. `cancelAuction(uint256 _auctionId)`: Allows the NFT owner to cancel an auction before it ends.
 *  17. `setMarketplaceFee(uint256 _feePercentage)`: Sets the marketplace fee percentage (admin function).
 *  18. `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 *
 * **Staking and Rewards:**
 *  19. `stakeNFT(uint256 _tokenId)`: Allows NFT owners to stake their NFTs to earn rewards.
 *  20. `unstakeNFT(uint256 _tokenId)`: Allows NFT owners to unstake their NFTs.
 *  21. `claimStakingRewards(uint256 _tokenId)`: Allows NFT owners to claim accumulated staking rewards.
 *  22. `setStakingRewardRate(uint256 _rewardRate)`: Sets the staking reward rate (admin function).
 *
 * **Governance (Simple Example - Can be expanded):**
 *  23. `submitProposal(string memory _proposalDescription)`: Allows NFT holders to submit governance proposals.
 *  24. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on active proposals.
 *  25. `executeProposal(uint256 _proposalId)`: Executes a passed proposal (simple example - only owner can execute).
 *
 * **Utility & Admin:**
 *  26. `pauseMarketplace()`: Pauses marketplace functionalities (admin function).
 *  27. `unpauseMarketplace()`: Unpauses marketplace functionalities (admin function).
 *  28. `emergencyWithdraw(address _recipient)`: Allows the contract owner to withdraw any stuck tokens or Ether in case of emergency.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DynamicNFTMarketplace is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    string private _baseTokenURI;

    // Dynamic NFT Traits
    mapping(uint256 => mapping(string => string)) private _dynamicTraits;

    // Marketplace Listings
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings;
    Counters.Counter private _listingIdCounter;

    // Dutch Auctions
    struct Auction {
        uint256 tokenId;
        address seller;
        uint256 startingBid;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }
    mapping(uint256 => Auction) public auctions;
    Counters.Counter private _auctionIdCounter;

    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    address payable public marketplaceFeeRecipient;

    // Staking
    mapping(uint256 => uint256) public nftStakeStartTime;
    mapping(uint256 => bool) public isNFTStaked;
    uint256 public stakingRewardRate = 10**15; // Example: 0.001 ETH per day per staked NFT (adjust as needed)
    uint256 public lastRewardUpdate;

    // Governance (Simple Proposal System)
    struct Proposal {
        string description;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool isActive;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted

    bool public paused;

    event NFTMinted(uint256 tokenId, address to, string baseURI);
    event MetadataURISet(string baseURI);
    event DynamicTraitSet(uint256 tokenId, string traitName, string traitValue);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event NFTSaleCancelled(uint256 listingId, uint256 tokenId);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startingBid, uint256 endTime);
    event AuctionBid(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionSettled(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event AuctionCancelled(uint256 auctionId, uint256 tokenId);
    event MarketplaceFeeSet(uint256 feePercentage);
    event FeesWithdrawn(address recipient, uint256 amount);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event StakingRewardsClaimed(uint256 tokenId, address claimer, uint256 rewardAmount);
    event StakingRewardRateSet(uint256 rewardRate);
    event ProposalSubmitted(uint256 proposalId, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event EmergencyWithdrawal(address recipient, uint256 amount);

    modifier whenNotPaused() {
        require(!paused, "Marketplace is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Marketplace is not paused");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        require(_msgSender() == ownerOf(_tokenId), "Not NFT owner");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _baseURI, address payable _feeRecipient) ERC721(_name, _symbol) {
        _baseTokenURI = _baseURI;
        marketplaceFeeRecipient = _feeRecipient;
    }

    // ------------------------------------------------------------------------
    //                              NFT Management
    // ------------------------------------------------------------------------

    /// @notice Mints a new Dynamic NFT to the specified address.
    /// @param _to The address to mint the NFT to.
    /// @param _baseURI The base URI for the NFT metadata.
    function mintNFT(address _to, string memory _baseURI) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);
        _setBaseURI(_baseURI); // Set base URI at mint time
        emit NFTMinted(tokenId, _to, _baseURI);
    }

    /// @notice Sets the base URI for NFT metadata.
    /// @param _baseURI The new base URI.
    function setBaseMetadataURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
        emit MetadataURISet(_baseURI);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Transfers ownership of an NFT. (Internal function, used by marketplace)
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) internal {
        _transfer(ownerOf(_tokenId), _to, _tokenId);
    }

    /// @notice Approves an address to operate on a specific NFT.
    /// @inheritdoc ERC721
    function approveNFT(address _approved, uint256 _tokenId) public onlyNFTOwner(_tokenId) {
        approve(_approved, _tokenId);
    }

    /// @notice Gets the approved address for a specific NFT.
    /// @inheritdoc ERC721
    function getApprovedNFT(uint256 _tokenId) public view returns (address) {
        return getApproved(_tokenId);
    }


    /// @notice Sets a dynamic trait for an NFT.
    /// @dev This allows for evolving NFT metadata.
    /// @param _tokenId The ID of the NFT to modify.
    /// @param _traitName The name of the trait.
    /// @param _traitValue The value of the trait.
    function setDynamicTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue) public onlyNFTOwner(_tokenId) {
        _dynamicTraits[_tokenId][_traitName] = _traitValue;
        emit DynamicTraitSet(_tokenId, _traitName, _traitValue);
        // Consider emitting an event to signal metadata update for off-chain refresh
    }

    /// @notice Retrieves a dynamic trait value for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @param _traitName The name of the trait to retrieve.
    /// @return The value of the dynamic trait.
    function getDynamicTrait(uint256 _tokenId, string memory _traitName) public view returns (string memory) {
        return _dynamicTraits[_tokenId][_traitName];
    }

    /// @notice Triggers the evolution of an NFT based on predefined conditions (example: time-based).
    /// @dev This is a placeholder for more complex evolution logic. In a real application,
    ///      evolution could be triggered by various on-chain or off-chain events.
    ///      For this example, let's assume a simple time-based evolution.
    ///      In a real-world scenario, you'd likely integrate with Chainlink Keepers or similar
    ///      for automated, decentralized evolution triggers.
    /// @param _tokenId The ID of the NFT to evolve.
    function evolveNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) {
        // Example: Simple time-based evolution - after 7 days (example)
        if (block.timestamp > nftStakeStartTime[_tokenId] + 7 days) { // Example condition - adjust as needed
            string memory currentLevel = getDynamicTrait(_tokenId, "level");
            uint256 level = 1;
            if (bytes(currentLevel).length > 0) {
                level = uint256(Strings.parseInt(currentLevel)) + 1;
            }
            setDynamicTrait(_tokenId, "level", level.toString());
            setDynamicTrait(_tokenId, "evolvedAt", block.timestamp.toString());
            // In a real system, you might update more traits, change images, etc. based on evolution
        } else {
            revert("NFT evolution conditions not met yet.");
        }
    }


    // ------------------------------------------------------------------------
    //                          Marketplace Operations
    // ------------------------------------------------------------------------

    /// @notice Lists an NFT for sale on the marketplace.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The listing price in wei.
    function listNFTForSale(uint256 _tokenId, uint256 _price) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(getApproved(_tokenId) == address(this) || ownerOf(_tokenId) == _msgSender(), "Not approved or owner"); // Ensure contract is approved
        require(_price > 0, "Price must be greater than zero");
        require(!isNFTStaked[_tokenId], "NFT is currently staked and cannot be listed.");

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        listings[listingId] = Listing({
            tokenId: _tokenId,
            seller: _msgSender(),
            price: _price,
            isActive: true
        });

        approve(address(this), _tokenId); // Approve marketplace to handle NFT transfer

        emit NFTListed(listingId, _tokenId, _msgSender(), _price);
    }

    /// @notice Allows anyone to buy a listed NFT.
    /// @param _listingId The ID of the listing to buy.
    function buyNFT(uint256 _listingId) public payable whenNotPaused nonReentrant {
        require(listings[_listingId].isActive, "Listing is not active");
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds sent");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - marketplaceFee;

        listing.isActive = false; // Deactivate listing

        // Transfer NFT to buyer
        transferNFT(_msgSender(), listing.tokenId);

        // Transfer funds to seller and marketplace
        payable(listing.seller).transfer(sellerProceeds);
        marketplaceFeeRecipient.transfer(marketplaceFee);

        emit NFTBought(_listingId, listing.tokenId, _msgSender(), listing.price);
    }

    /// @notice Allows the NFT owner to cancel a sale listing.
    /// @param _listingId The ID of the listing to cancel.
    function cancelNFTSale(uint256 _listingId) public whenNotPaused {
        require(listings[_listingId].isActive, "Listing is not active");
        require(listings[_listingId].seller == _msgSender(), "Not listing owner");
        listings[_listingId].isActive = false;
        emit NFTSaleCancelled(_listingId, listings[_listingId].tokenId);
    }

    /// @notice Creates a Dutch auction for an NFT.
    /// @param _tokenId The ID of the NFT to auction.
    /// @param _startingBid The starting bid price in wei.
    /// @param _auctionDuration The duration of the auction in seconds.
    function createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(getApproved(_tokenId) == address(this) || ownerOf(_tokenId) == _msgSender(), "Not approved or owner"); // Ensure contract is approved
        require(_startingBid > 0, "Starting bid must be greater than zero");
        require(_auctionDuration > 0, "Auction duration must be greater than zero");
        require(!isNFTStaked[_tokenId], "NFT is currently staked and cannot be auctioned.");

        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();

        auctions[auctionId] = Auction({
            tokenId: _tokenId,
            seller: _msgSender(),
            startingBid: _startingBid,
            endTime: block.timestamp + _auctionDuration,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });

        approve(address(this), _tokenId); // Approve marketplace to handle NFT transfer

        emit AuctionCreated(auctionId, _tokenId, _msgSender(), _startingBid, block.timestamp + _auctionDuration);
    }

    /// @notice Allows users to bid on an active auction.
    /// @param _auctionId The ID of the auction to bid on.
    function bidOnAuction(uint256 _auctionId) public payable whenNotPaused nonReentrant {
        require(auctions[_auctionId].isActive, "Auction is not active");
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.value > auction.highestBid, "Bid must be higher than current highest bid");

        if (auction.highestBidder != address(0)) {
            // Refund previous highest bidder
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = _msgSender();
        auction.highestBid = msg.value;
        emit AuctionBid(_auctionId, _msgSender(), msg.value);
    }

    /// @notice Settles a completed auction and transfers NFT to the highest bidder.
    /// @param _auctionId The ID of the auction to settle.
    function settleAuction(uint256 _auctionId) public whenNotPaused nonReentrant {
        require(auctions[_auctionId].isActive, "Auction is not active");
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction is not yet ended");
        require(auction.highestBidder != address(0), "No bids placed on auction");

        auction.isActive = false; // Deactivate auction

        uint256 marketplaceFee = (auction.highestBid * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = auction.highestBid - marketplaceFee;

        // Transfer NFT to winner
        transferNFT(auction.highestBidder, auction.tokenId);

        // Transfer funds to seller and marketplace
        payable(auction.seller).transfer(sellerProceeds);
        marketplaceFeeRecipient.transfer(marketplaceFee);

        emit AuctionSettled(_auctionId, auction.tokenId, auction.highestBidder, auction.highestBid);
    }

    /// @notice Allows the NFT owner to cancel an auction before it ends.
    /// @param _auctionId The ID of the auction to cancel.
    function cancelAuction(uint256 _auctionId) public whenNotPaused {
        require(auctions[_auctionId].isActive, "Auction is not active");
        require(auctions[_auctionId].seller == _msgSender(), "Not auction owner");
        require(block.timestamp < auctions[_auctionId].endTime, "Auction has already ended");
        auctions[_auctionId].isActive = false;

        if (auctions[_auctionId].highestBidder != address(0)) {
            // Refund the highest bidder
            payable(auctions[_auctionId].highestBidder).transfer(auctions[_auctionId].highestBid);
        }

        emit AuctionCancelled(_auctionId, auctions[_auctionId].tokenId);
    }

    /// @notice Sets the marketplace fee percentage (admin function).
    /// @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 1000, "Fee percentage cannot exceed 100%"); // Limit to reasonable percentage (e.g., 10%)
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /// @notice Allows the contract owner to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 contractBalance = balance - msg.value; // Subtract msg.value to account for gas costs
        require(contractBalance > 0, "No fees to withdraw");

        uint256 withdrawAmount = contractBalance; // Withdraw all available fees
        marketplaceFeeRecipient.transfer(withdrawAmount);
        emit FeesWithdrawn(marketplaceFeeRecipient, withdrawAmount);
    }


    // ------------------------------------------------------------------------
    //                           Staking and Rewards
    // ------------------------------------------------------------------------

    /// @notice Allows NFT owners to stake their NFTs to earn rewards.
    /// @param _tokenId The ID of the NFT to stake.
    function stakeNFT(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) nonReentrant {
        require(!isNFTStaked[_tokenId], "NFT is already staked");
        require(!listings[_tokenId].isActive, "Cannot stake NFT that is listed for sale.");
        require(!auctions[getAuctionIdForToken(_tokenId)].isActive, "Cannot stake NFT that is in auction.");

        isNFTStaked[_tokenId] = true;
        nftStakeStartTime[_tokenId] = block.timestamp;
        lastRewardUpdate = block.timestamp; // Update last reward time on stake
        approve(address(this), _tokenId); // Approve marketplace to manage NFT while staked
        emit NFTStaked(_tokenId, _msgSender());
    }

    /// @notice Allows NFT owners to unstake their NFTs.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) nonReentrant {
        require(isNFTStaked[_tokenId], "NFT is not staked");
        claimStakingRewards(_tokenId); // Automatically claim rewards before unstaking
        isNFTStaked[_tokenId] = false;
        nftStakeStartTime[_tokenId] = 0; // Reset stake start time
        emit NFTUnstaked(_tokenId, _msgSender());
    }

    /// @notice Allows NFT owners to claim accumulated staking rewards.
    /// @param _tokenId The ID of the NFT to claim rewards for.
    function claimStakingRewards(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) nonReentrant {
        require(isNFTStaked[_tokenId], "NFT is not staked");
        uint256 rewardAmount = calculateStakingRewards(_tokenId);
        require(rewardAmount > 0, "No rewards to claim");

        lastRewardUpdate = block.timestamp; // Update last reward time on claim

        payable(_msgSender()).transfer(rewardAmount);
        emit StakingRewardsClaimed(_tokenId, _msgSender(), rewardAmount);
    }

    /// @dev Calculates the staking rewards for a given NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The calculated staking reward amount.
    function calculateStakingRewards(uint256 _tokenId) public view returns (uint256) {
        if (!isNFTStaked[_tokenId]) {
            return 0; // No rewards if not staked
        }
        uint256 timeElapsed = block.timestamp - nftStakeStartTime[_tokenId];
        uint256 rewardPerDay = stakingRewardRate;
        uint256 rewardAmount = (timeElapsed / 1 days) * rewardPerDay; // Example: daily rewards
        return rewardAmount;
    }

    /// @notice Sets the staking reward rate (admin function).
    /// @param _rewardRate The new staking reward rate (e.g., wei per day per NFT).
    function setStakingRewardRate(uint256 _rewardRate) public onlyOwner {
        stakingRewardRate = _rewardRate;
        emit StakingRewardRateSet(_rewardRate);
    }


    // ------------------------------------------------------------------------
    //                              Governance
    // ------------------------------------------------------------------------

    /// @notice Allows NFT holders to submit governance proposals.
    /// @param _proposalDescription The description of the proposal.
    function submitProposal(string memory _proposalDescription) public whenNotPaused {
        require(balanceOf(_msgSender()) > 0, "Must hold at least one NFT to submit proposal");
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        proposals[proposalId] = Proposal({
            description: _proposalDescription,
            voteCountYes: 0,
            voteCountNo: 0,
            isActive: true,
            executed: false
        });
        emit ProposalSubmitted(proposalId, _proposalDescription, _msgSender());
    }

    /// @notice Allows NFT holders to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for Yes, False for No.
    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(proposals[_proposalId].isActive, "Proposal is not active");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(!hasVoted[_proposalId][_msgSender()], "Already voted on this proposal");
        require(balanceOf(_msgSender()) > 0, "Must hold at least one NFT to vote");

        hasVoted[_proposalId][_msgSender()] = true;
        if (_vote) {
            proposals[_proposalId].voteCountYes++;
        } else {
            proposals[_proposalId].voteCountNo++;
        }
        emit VoteCast(_proposalId, _msgSender(), _vote);
    }

    /// @notice Executes a passed proposal (simple example - only owner can execute).
    /// @dev In a more advanced system, execution could be automated based on vote thresholds.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused {
        require(proposals[_proposalId].isActive, "Proposal is not active");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(proposals[_proposalId].voteCountYes > proposals[_proposalId].voteCountNo, "Proposal did not pass"); // Simple majority example

        proposals[_proposalId].isActive = false;
        proposals[_proposalId].executed = true;
        // Here you would implement the logic based on the proposal description.
        // For this simple example, we just mark it as executed.
        emit ProposalExecuted(_proposalId);
    }


    // ------------------------------------------------------------------------
    //                             Utility & Admin
    // ------------------------------------------------------------------------

    /// @notice Pauses marketplace functionalities (admin function).
    function pauseMarketplace() public onlyOwner whenNotPaused {
        paused = true;
        emit MarketplacePaused();
    }

    /// @notice Unpauses marketplace functionalities (admin function).
    function unpauseMarketplace() public onlyOwner whenPaused {
        paused = false;
        emit MarketplaceUnpaused();
    }

    /// @notice Allows the contract owner to withdraw any stuck tokens or Ether in case of emergency.
    /// @param _recipient The address to withdraw funds to.
    function emergencyWithdraw(address _recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(_recipient).transfer(balance);
            emit EmergencyWithdrawal(_recipient, balance);
        }

        // Add logic for withdrawing stuck ERC20 tokens if needed.
    }

    // ------------------------------------------------------------------------
    //                      ERC721 Enumerable Overrides
    // ------------------------------------------------------------------------

    /// @inheritdoc ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @inheritdoc ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ------------------------------------------------------------------------
    //                      Helper Functions (Internal/Private)
    // ------------------------------------------------------------------------

    /// @dev Internal helper to get the auction ID for a given token ID.
    /// @param _tokenId The token ID.
    /// @return The auction ID or 0 if no active auction found for the token.
    function getAuctionIdForToken(uint256 _tokenId) internal view returns (uint256) {
        for (uint256 i = 1; i <= _auctionIdCounter.current(); i++) {
            if (auctions[i].isActive && auctions[i].tokenId == _tokenId) {
                return i;
            }
        }
        return 0; // No active auction found for this token
    }
}
```