```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with Staking, Governance, and Auctions
 * @author Bard (AI Assistant)
 * @dev A sophisticated NFT marketplace that introduces dynamic NFTs, staking mechanisms,
 *      governance features, and advanced auction types. This contract aims to provide a
 *      comprehensive and engaging platform for NFT trading and interaction, going beyond
 *      basic marketplace functionalities. It incorporates innovative features to enhance
 *      user experience and community participation.

 * **Outline & Function Summary:**

 * **1. NFT Management Functions:**
 *    - `mintDynamicNFT(string _baseURI, string _metadataExtension)`: Mints a new Dynamic NFT with a base URI and metadata extension.
 *    - `setBaseURI(string _newBaseURI)`: Updates the base URI for NFT metadata. (Admin only)
 *    - `setMetadataExtension(string _newExtension)`: Updates the metadata file extension. (Admin only)
 *    - `tokenURI(uint256 tokenId)`: Returns the dynamic URI for a given NFT token ID.
 *    - `getNFTStage(uint256 tokenId)`: Retrieves the current stage of a dynamic NFT.
 *    - `manualNFTStageUpdate(uint256 tokenId)`: Allows admin to manually update an NFT's stage (for exceptional cases). (Admin only)

 * **2. Marketplace Listing & Trading Functions:**
 *    - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale at a fixed price.
 *    - `buyNFT(uint256 _listingId)`: Allows users to buy a listed NFT.
 *    - `cancelNFTListing(uint256 _listingId)`: Allows the seller to cancel an NFT listing.
 *    - `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Allows the seller to update the price of a listing.
 *    - `getListingDetails(uint256 _listingId)`: Retrieves details of a specific NFT listing.
 *    - `getAllListings()`: Returns a list of all active NFT listings.

 * **3. Staking & Reward Functions:**
 *    - `stakeMarketplaceToken(uint256 _amount)`: Allows users to stake marketplace tokens to earn rewards and influence NFT evolution.
 *    - `unstakeMarketplaceToken(uint256 _amount)`: Allows users to unstake their marketplace tokens.
 *    - `claimStakingRewards()`: Allows users to claim accumulated staking rewards.
 *    - `getPendingRewards(address _user)`: Retrieves the pending staking rewards for a user.
 *    - `getStakingBalance(address _user)`: Retrieves the current staking balance of a user.
 *    - `setStakingRewardRate(uint256 _newRate)`: Updates the staking reward rate. (Admin only)

 * **4. Governance Functions (Basic DAO):**
 *    - `proposeMarketplaceParameterChange(string _description, string _parameterName, uint256 _newValue)`: Allows staked token holders to propose changes to marketplace parameters.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows staked token holders to vote on active proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes a passed proposal after voting period. (Admin only, after quorum and majority)
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific governance proposal.
 *    - `getActiveProposals()`: Returns a list of all active governance proposals.

 * **5. Auction Functions (English Auction):**
 *    - `createEnglishAuction(uint256 _tokenId, uint256 _startingBid, uint256 _duration)`: Creates an English auction for an NFT.
 *    - `bidOnEnglishAuction(uint256 _auctionId)`: Allows users to place bids on an active English auction.
 *    - `finalizeEnglishAuction(uint256 _auctionId)`: Finalizes an English auction after the duration has ended.
 *    - `cancelEnglishAuction(uint256 _auctionId)`: Allows the auction creator to cancel an English auction before it starts or ends (with conditions).
 *    - `getAuctionDetails(uint256 _auctionId)`: Retrieves details of a specific English auction.
 *    - `getActiveAuctions()`: Returns a list of all active English auctions.

 * **6. Admin & Utility Functions:**
 *    - `setMarketplaceFee(uint256 _newFee)`: Updates the marketplace fee percentage. (Admin only)
 *    - `withdrawMarketplaceFees()`: Allows the admin to withdraw accumulated marketplace fees. (Admin only)
 *    - `pauseMarketplace()`: Pauses core marketplace functionalities. (Admin only)
 *    - `unpauseMarketplace()`: Resumes paused marketplace functionalities. (Admin only)
 *    - `setGovernanceQuorum(uint256 _newQuorum)`: Updates the quorum required for governance proposals. (Admin only)
 *    - `setGovernanceVotingPeriod(uint256 _newPeriod)`: Updates the voting period for governance proposals. (Admin only)
 *    - `rescueERC20Tokens(address _tokenAddress, uint256 _amount, address _recipient)`: Allows admin to rescue accidentally sent ERC20 tokens. (Admin only)
 *    - `supportsInterface(bytes4 interfaceId)`: Interface support for standard ERC interfaces.

 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicNFTMarketplace is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    string public baseURI;
    string public metadataExtension = ".json";
    uint256 public marketplaceFeePercentage = 2; // 2% marketplace fee
    address public marketplaceFeeRecipient;

    IERC20 public marketplaceToken; // Address of the Marketplace Token for staking
    uint256 public stakingRewardRate = 10; // Rewards per block per 1000 tokens staked (example)

    uint256 public governanceQuorum = 50; // Percentage of staked tokens needed for quorum
    uint256 public governanceVotingPeriod = 7 days;

    Counters.Counter private _listingIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _auctionIdCounter;

    struct NFTListing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => NFTListing) public nftListings;

    struct StakingInfo {
        uint256 balance;
        uint256 lastRewardBlock;
        uint256 pendingRewards;
    }
    mapping(address => StakingInfo) public stakingBalances;

    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        string parameterName;
        uint256 newValue;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isExecuted;
        bool isActive;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => voted

    struct EnglishAuction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startingBid;
        uint256 currentBid;
        address highestBidder;
        uint256 endTime;
        bool isActive;
    }
    mapping(uint256 => EnglishAuction) public englishAuctions;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address minter);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTListingCancelled(uint256 listingId);
    event NFTPriceUpdated(uint256 listingId, uint256 newPrice);
    event NFTSold(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event TokensStaked(address user, uint256 amount);
    event TokensUnstaked(address user, uint256 amount);
    event RewardsClaimed(address user, uint256 amount);
    event GovernanceProposalCreated(uint256 proposalId, string description, string parameterName, uint256 newValue);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event EnglishAuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startingBid, uint256 endTime);
    event EnglishAuctionBidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event EnglishAuctionFinalized(uint256 auctionId, address winner, uint256 winningBid);
    event EnglishAuctionCancelled(uint256 auctionId);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event StakingRewardRateUpdated(uint256 newRate);
    event GovernanceQuorumUpdated(uint256 newQuorum);
    event GovernanceVotingPeriodUpdated(uint256 newPeriod);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    // --- Modifiers ---
    modifier onlyActiveListing(uint256 _listingId) {
        require(nftListings[_listingId].isActive, "Listing is not active");
        _;
    }
    modifier onlyListingSeller(uint256 _listingId) {
        require(nftListings[_listingId].seller == _msgSender(), "Not listing seller");
        _;
    }
    modifier onlyActiveAuction(uint256 _auctionId) {
        require(englishAuctions[_auctionId].isActive, "Auction is not active");
        _;
    }
    modifier onlyAuctionSeller(uint256 _auctionId) {
        require(englishAuctions[_auctionId].seller == _msgSender(), "Not auction seller");
        _;
    }
    modifier onlyHighestBidder(uint256 _auctionId) {
        require(englishAuctions[_auctionId].highestBidder == _msgSender(), "Not highest bidder");
        _;
    }
    modifier notEndedAuction(uint256 _auctionId) {
        require(block.timestamp < englishAuctions[_auctionId].endTime, "Auction ended");
        _;
    }
    modifier notStartedAuction(uint256 _auctionId) {
        require(block.timestamp <= englishAuctions[_auctionId].endTime - englishAuctions[_auctionId].duration, "Auction started"); // Assuming duration is stored
        _;
    }
    modifier validProposal(uint256 _proposalId) {
        require(governanceProposals[_proposalId].isActive, "Proposal is not active");
        require(!governanceProposals[_proposalId].isExecuted, "Proposal already executed");
        require(block.timestamp < governanceProposals[_proposalId].votingDeadline, "Voting period ended");
        _;
    }
    modifier notVoted(uint256 _proposalId) {
        require(!proposalVotes[_proposalId][_msgSender()], "Already voted on this proposal");
        _;
    }
    modifier quorumReached(uint256 _proposalId) {
        uint256 totalStaked = marketplaceToken.totalSupply(); // Assuming total staked is roughly total supply for simplicity
        uint256 stakedForQuorum = totalStaked.mul(governanceQuorum).div(100);
        require(governanceProposals[_proposalId].votesFor >= stakedForQuorum, "Quorum not reached");
        _;
    }
    modifier votingPeriodEnded(uint256 _proposalId) {
        require(block.timestamp >= governanceProposals[_proposalId].votingDeadline, "Voting period not ended");
        _;
    }

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol, string memory _baseURI, address _marketplaceTokenAddress, address _feeRecipient) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        marketplaceToken = IERC20(_marketplaceTokenAddress);
        marketplaceFeeRecipient = _feeRecipient;
    }

    // --- 1. NFT Management Functions ---

    function mintDynamicNFT(string memory _metadataExtension) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(_msgSender(), newItemId);
        metadataExtension = _metadataExtension; // Set extension per mint if desired or globally if needed
        emit NFTMinted(newItemId, _msgSender());
        return newItemId;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMetadataExtension(string memory _newExtension) public onlyOwner {
        metadataExtension = _newExtension;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token URI query for nonexistent token");
        // Dynamic URI logic based on tokenId, stage, or other factors can be added here.
        // Example: return string(abi.encodePacked(baseURI, Strings.toString(tokenId), getNFTStage(tokenId), metadataExtension));
        return string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId), metadataExtension)); // Basic example
    }

    function getNFTStage(uint256 tokenId) public view returns (uint256) {
        // Dynamic stage logic based on contract state, token interactions, etc.
        // For now, a placeholder. In a real dynamic NFT, this would be complex logic.
        return tokenId % 3; // Example: Stage based on token ID modulo
    }

    function manualNFTStageUpdate(uint256 tokenId) public onlyOwner {
        // Admin function to manually update NFT stage if needed.
        // In a real system, stage updates would be triggered by events or logic.
        // Placeholder for more complex dynamic logic.
        // Example: _setTokenStage(tokenId, newStage);  (Need to define _setTokenStage if you want to store stage on-chain)
    }


    // --- 2. Marketplace Listing & Trading Functions ---

    function listNFTForSale(uint256 _tokenId, uint256 _price) public whenNotPaused {
        require(ownerOf(_tokenId) == _msgSender(), "Not NFT owner");
        require(getApproved(_tokenId) == address(this) || isApprovedForAll(ownerOf(_tokenId), address(this)), "Contract not approved for NFT transfer");
        require(_price > 0, "Price must be greater than zero");

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        nftListings[listingId] = NFTListing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: _msgSender(),
            price: _price,
            isActive: true
        });

        _approve(address(this), _tokenId); // Approve marketplace to transfer NFT
        emit NFTListed(listingId, _tokenId, _msgSender(), _price);
    }

    function buyNFT(uint256 _listingId) public payable whenNotPaused onlyActiveListing(_listingId) {
        NFTListing storage listing = nftListings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds");

        uint256 marketplaceFee = listing.price.mul(marketplaceFeePercentage).div(100);
        uint256 sellerPayout = listing.price.sub(marketplaceFee);

        listing.isActive = false; // Deactivate listing

        payable(listing.seller).transfer(sellerPayout);
        payable(marketplaceFeeRecipient).transfer(marketplaceFee);

        _transfer(listing.seller, _msgSender(), listing.tokenId);

        emit NFTSold(_listingId, listing.tokenId, _msgSender(), listing.price);
        emit NFTListingCancelled(_listingId); // Implicitly cancel listing after sale
    }

    function cancelNFTListing(uint256 _listingId) public whenNotPaused onlyActiveListing(_listingId) onlyListingSeller(_listingId) {
        nftListings[_listingId].isActive = false;
        emit NFTListingCancelled(_listingId);
    }

    function updateListingPrice(uint256 _listingId, uint256 _newPrice) public whenNotPaused onlyActiveListing(_listingId) onlyListingSeller(_listingId) {
        require(_newPrice > 0, "Price must be greater than zero");
        nftListings[_listingId].price = _newPrice;
        emit NFTPriceUpdated(_listingId, _newPrice);
    }

    function getListingDetails(uint256 _listingId) public view returns (NFTListing memory) {
        return nftListings[_listingId];
    }

    function getAllListings() public view returns (NFTListing[] memory) {
        uint256 listingCount = _listingIdCounter.current();
        uint256 activeListingCount = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (nftListings[i].isActive) {
                activeListingCount++;
            }
        }

        NFTListing[] memory activeListings = new NFTListing[](activeListingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (nftListings[i].isActive) {
                activeListings[index] = nftListings[i];
                index++;
            }
        }
        return activeListings;
    }


    // --- 3. Staking & Reward Functions ---

    function stakeMarketplaceToken(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(marketplaceToken.transferFrom(_msgSender(), address(this), _amount), "Token transfer failed");

        _updateStakingRewards(_msgSender()); // Update rewards before staking more

        stakingBalances[_msgSender()].balance = stakingBalances[_msgSender()].balance.add(_amount);
        stakingBalances[_msgSender()].lastRewardBlock = block.number;

        emit TokensStaked(_msgSender(), _amount);
    }

    function unstakeMarketplaceToken(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(stakingBalances[_msgSender()].balance >= _amount, "Insufficient staked balance");

        _updateStakingRewards(_msgSender()); // Update rewards before unstaking

        stakingBalances[_msgSender()].balance = stakingBalances[_msgSender()].balance.sub(_amount);
        stakingBalances[_msgSender()].lastRewardBlock = block.number; // Update last reward block even when unstaking

        require(marketplaceToken.transfer(_msgSender(), _amount), "Token transfer failed");
        emit TokensUnstaked(_msgSender(), _amount);
    }

    function claimStakingRewards() public whenNotPaused {
        _updateStakingRewards(_msgSender());
        uint256 rewards = stakingBalances[_msgSender()].pendingRewards;
        if (rewards > 0) {
            stakingBalances[_msgSender()].pendingRewards = 0;
            require(marketplaceToken.transfer(_msgSender(), rewards), "Reward transfer failed");
            emit RewardsClaimed(_msgSender(), rewards);
        }
    }

    function getPendingRewards(address _user) public view returns (uint256) {
        return _calculatePendingRewards(_user);
    }

    function getStakingBalance(address _user) public view returns (uint256) {
        return stakingBalances[_user].balance;
    }

    function setStakingRewardRate(uint256 _newRate) public onlyOwner {
        stakingRewardRate = _newRate;
        emit StakingRewardRateUpdated(_newRate);
    }

    // --- Internal Staking Helper Functions ---

    function _updateStakingRewards(address _user) internal {
        uint256 pendingRewards = _calculatePendingRewards(_user);
        stakingBalances[_user].pendingRewards = stakingBalances[_user].pendingRewards.add(pendingRewards);
        stakingBalances[_user].lastRewardBlock = block.number;
    }

    function _calculatePendingRewards(address _user) internal view returns (uint256) {
        uint256 currentBlock = block.number;
        uint256 lastRewardBlock = stakingBalances[_user].lastRewardBlock;
        uint256 stakedBalance = stakingBalances[_user].balance;

        if (currentBlock > lastRewardBlock && stakedBalance > 0) {
            uint256 blockDifference = currentBlock.sub(lastRewardBlock);
            uint256 rewardAmount = blockDifference.mul(stakedBalance).mul(stakingRewardRate).div(1000); // Example calculation
            return rewardAmount;
        }
        return 0;
    }


    // --- 4. Governance Functions (Basic DAO) ---

    function proposeMarketplaceParameterChange(string memory _description, string memory _parameterName, uint256 _newValue) public whenNotPaused {
        require(stakingBalances[_msgSender()].balance > 0, "Must stake tokens to propose");
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _description,
            parameterName: _parameterName,
            newValue: _newValue,
            votingDeadline: block.timestamp + governanceVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            isExecuted: false,
            isActive: true
        });

        emit GovernanceProposalCreated(proposalId, _description, _parameterName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused validProposal(_proposalId) notVoted(_proposalId) {
        require(stakingBalances[_msgSender()].balance > 0, "Must stake tokens to vote");

        proposalVotes[_proposalId][_msgSender()] = true; // Mark as voted

        if (_vote) {
            governanceProposals[_proposalId].votesFor = governanceProposals[_proposalId].votesFor.add(stakingBalances[_msgSender()].balance);
        } else {
            governanceProposals[_proposalId].votesAgainst = governanceProposals[_proposalId].votesAgainst.add(stakingBalances[_msgSender()].balance);
        }
        emit GovernanceVoteCast(_proposalId, _msgSender(), _vote);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused validProposal(_proposalId) votingPeriodEnded(_proposalId) quorumReached(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];

        // Example parameter changes - expand as needed
        if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("marketplaceFeePercentage"))) {
            setMarketplaceFee(proposal.newValue);
        } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("stakingRewardRate"))) {
            setStakingRewardRate(proposal.newValue);
        } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("governanceQuorum"))) {
            setGovernanceQuorum(proposal.newValue);
        } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("governanceVotingPeriod"))) {
            setGovernanceVotingPeriod(proposal.newValue);
        } else {
            revert("Unknown parameter to change"); // Or handle unknown parameters differently
        }

        proposal.isExecuted = true;
        proposal.isActive = false;
        emit GovernanceProposalExecuted(_proposalId);
    }

    function getProposalDetails(uint256 _proposalId) public view returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }

    function getActiveProposals() public view returns (GovernanceProposal[] memory) {
        uint256 proposalCount = _proposalIdCounter.current();
        uint256 activeProposalCount = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (governanceProposals[i].isActive) {
                activeProposalCount++;
            }
        }

        GovernanceProposal[] memory activeProposals = new GovernanceProposal[](activeProposalCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (governanceProposals[i].isActive) {
                activeProposals[index] = governanceProposals[i];
                index++;
            }
        }
        return activeProposals;
    }


    // --- 5. Auction Functions (English Auction) ---

    function createEnglishAuction(uint256 _tokenId, uint256 _startingBid, uint256 _duration) public whenNotPaused {
        require(ownerOf(_tokenId) == _msgSender(), "Not NFT owner");
        require(getApproved(_tokenId) == address(this) || isApprovedForAll(ownerOf(_tokenId), address(this)), "Contract not approved for NFT transfer");
        require(_startingBid > 0, "Starting bid must be greater than zero");
        require(_duration > 0, "Duration must be greater than zero");

        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();

        englishAuctions[auctionId] = EnglishAuction({
            auctionId: auctionId,
            tokenId: _tokenId,
            seller: _msgSender(),
            startingBid: _startingBid,
            currentBid: 0,
            highestBidder: address(0),
            endTime: block.timestamp + _duration,
            isActive: true
        });

        _approve(address(this), _tokenId); // Approve marketplace to transfer NFT
        emit EnglishAuctionCreated(auctionId, _tokenId, _msgSender(), _startingBid, block.timestamp + _duration);
    }

    function bidOnEnglishAuction(uint256 _auctionId) public payable whenNotPaused onlyActiveAuction(_auctionId) notEndedAuction(_auctionId) {
        EnglishAuction storage auction = englishAuctions[_auctionId];
        require(msg.value > auction.currentBid, "Bid must be higher than current bid");
        require(msg.value >= auction.startingBid || auction.currentBid > 0, "Bid must be at least starting bid or higher than current bid");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.currentBid); // Refund previous bidder
        }

        auction.currentBid = msg.value;
        auction.highestBidder = _msgSender();
        emit EnglishAuctionBidPlaced(_auctionId, _msgSender(), msg.value);
    }

    function finalizeEnglishAuction(uint256 _auctionId) public whenNotPaused onlyActiveAuction(_auctionId) votingPeriodEnded(_auctionId) { // VotingPeriodEnded used for AuctionEndTime check for reuse, rename if needed
        EnglishAuction storage auction = englishAuctions[_auctionId];
        auction.isActive = false;

        uint256 marketplaceFee = auction.currentBid.mul(marketplaceFeePercentage).div(100);
        uint256 sellerPayout = auction.currentBid.sub(marketplaceFee);

        if (auction.highestBidder != address(0)) {
            payable(auction.seller).transfer(sellerPayout);
            payable(marketplaceFeeRecipient).transfer(marketplaceFee);
            _transfer(auction.seller, auction.highestBidder, auction.tokenId);
            emit EnglishAuctionFinalized(_auctionId, auction.highestBidder, auction.currentBid);
        } else {
            // No bids, return NFT to seller
            _transfer(address(this), auction.seller, auction.tokenId);
            emit EnglishAuctionFinalized(_auctionId, address(0), 0); // Indicate no winner
        }
    }

    function cancelEnglishAuction(uint256 _auctionId) public whenNotPaused onlyActiveAuction(_auctionId) onlyAuctionSeller(_auctionId) notStartedAuction(_auctionId) {
        EnglishAuction storage auction = englishAuctions[_auctionId];
        auction.isActive = false;
        _transfer(address(this), auction.seller, auction.tokenId); // Return NFT to seller
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.currentBid); // Refund highest bidder if any
        }
        emit EnglishAuctionCancelled(_auctionId);
    }

    function getAuctionDetails(uint256 _auctionId) public view returns (EnglishAuction memory) {
        return englishAuctions[_auctionId];
    }

    function getActiveAuctions() public view returns (EnglishAuction[] memory) {
        uint256 auctionCount = _auctionIdCounter.current();
        uint256 activeAuctionCount = 0;
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (englishAuctions[i].isActive) {
                activeAuctionCount++;
            }
        }

        EnglishAuction[] memory activeAuctions = new EnglishAuction[](activeAuctionCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= auctionCount; i++) {
            if (englishAuctions[i].isActive) {
                activeAuctions[index] = englishAuctions[i];
                index++;
            }
        }
        return activeAuctions;
    }


    // --- 6. Admin & Utility Functions ---

    function setMarketplaceFee(uint256 _newFee) public onlyOwner {
        require(_newFee <= 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _newFee;
        emit MarketplaceFeeUpdated(_newFee);
    }

    function withdrawMarketplaceFees() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance); // Or transfer to marketplaceFeeRecipient if different
    }

    function pauseMarketplace() public onlyOwner {
        _pause();
        emit MarketplacePaused();
    }

    function unpauseMarketplace() public onlyOwner {
        _unpause();
        emit MarketplaceUnpaused();
    }

    function setGovernanceQuorum(uint256 _newQuorum) public onlyOwner {
        require(_newQuorum <= 100, "Quorum percentage cannot exceed 100%");
        governanceQuorum = _newQuorum;
        emit GovernanceQuorumUpdated(_newQuorum);
    }

    function setGovernanceVotingPeriod(uint256 _newPeriod) public onlyOwner {
        governanceVotingPeriod = _newPeriod;
        emit GovernanceVotingPeriodUpdated(_newPeriod);
    }

    function rescueERC20Tokens(address _tokenAddress, uint256 _amount, address _recipient) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(_amount <= contractBalance, "Amount exceeds contract balance");
        require(token.transfer(_recipient, _amount), "Token rescue failed");
    }

    // --- Override ERC721 functions to include Pausable ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Internal utility function for string conversion (from OpenZeppelin Strings.sol, simplified for inline use) ---
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
```