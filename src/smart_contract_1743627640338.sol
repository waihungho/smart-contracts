```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery.
 *
 * Outline and Function Summary:
 *
 * 1.  **Artwork Management:**
 *     - `mintArtwork(string memory _artworkCID, string memory _metadataCID)`: Allows artists to mint new artworks (NFTs).
 *     - `setArtworkPrice(uint256 _artworkId, uint256 _price)`: Allows artists to set the price of their artworks for direct sale.
 *     - `listArtworkForAuction(uint256 _artworkId, uint256 _startPrice, uint256 _duration)`: Allows artists to list their artworks for auction.
 *     - `cancelArtworkListing(uint256 _artworkId)`: Allows artists to cancel a direct sale or auction listing.
 *     - `burnArtwork(uint256 _artworkId)`: Allows artists to burn their own artwork (NFT) under certain conditions (e.g., if not sold).
 *     - `transferArtworkOwnership(uint256 _artworkId, address _to)`: Allows artwork owners to transfer ownership to another address.
 *     - `getArtworkDetails(uint256 _artworkId)`: Returns detailed information about a specific artwork.
 *     - `getArtistArtworks(address _artist)`: Returns a list of artwork IDs owned by a specific artist.
 *
 * 2.  **Gallery Management & Curation (DAO-like aspects):**
 *     - `proposeArtworkForExhibition(uint256 _artworkId)`:  Allows curators to propose artworks for a virtual gallery exhibition.
 *     - `voteOnExhibitionProposal(uint256 _proposalId, bool _vote)`: Allows gallery members/token holders to vote on exhibition proposals.
 *     - `executeExhibitionProposal(uint256 _proposalId)`: Executes an approved exhibition proposal, featuring the artwork in the gallery.
 *     - `addCurator(address _curator)`:  Allows the contract owner to add new curators.
 *     - `removeCurator(address _curator)`: Allows the contract owner to remove curators.
 *     - `setGalleryCommissionFee(uint256 _feePercentage)`: Allows the contract owner to set the gallery commission fee on sales.
 *
 * 3.  **Marketplace & Sales:**
 *     - `purchaseArtwork(uint256 _artworkId)`: Allows users to purchase artworks listed for direct sale.
 *     - `bidOnArtworkAuction(uint256 _artworkId)`: Allows users to place bids on artworks in auction.
 *     - `finalizeArtworkAuction(uint256 _artworkId)`: Allows anyone to finalize an auction after its duration ends, distributing funds.
 *     - `withdrawArtistEarnings()`: Allows artists to withdraw their earnings from artwork sales.
 *     - `withdrawGalleryCommission()`: Allows the contract owner to withdraw accumulated gallery commission fees.
 *
 * 4.  **Reputation & Artist Tiers (Advanced Concept):**
 *     - `reportArtwork(uint256 _artworkId, string memory _reason)`: Allows users to report artworks for policy violations (e.g., inappropriate content).
 *     - `upvoteArtist(address _artist)`: Allows users to upvote artists, contributing to a reputation score.
 *     - `downvoteArtist(address _artist)`: Allows users to downvote artists, potentially affecting their tier.
 *     - `getArtistReputation(address _artist)`: Returns the reputation score of an artist.
 *     - `setArtistTierThresholds(uint256[] memory _thresholds, string[] memory _tierNames)`: Allows the contract owner to define artist reputation tiers and thresholds.
 *     - `getArtistTier(address _artist)`: Returns the tier of an artist based on their reputation.
 *
 * 5.  **Utility & View Functions:**
 *     - `getGalleryBalance()`: Returns the current balance of the gallery contract.
 *     - `isArtworkListedForSale(uint256 _artworkId)`: Checks if an artwork is currently listed for direct sale.
 *     - `isArtworkInAuction(uint256 _artworkId)`: Checks if an artwork is currently in auction.
 *     - `isCurator(address _account)`: Checks if an address is a registered curator.
 *     - `getGalleryCommissionFee()`: Returns the current gallery commission fee percentage.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedAutonomousArtGallery is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    Counters.Counter private _artworkIds;

    // Struct to hold artwork details
    struct Artwork {
        uint256 artworkId;
        string artworkCID; // CID for the artwork file (e.g., IPFS)
        string metadataCID; // CID for artwork metadata (e.g., IPFS)
        address artist;
        uint256 price; // Price for direct sale (0 if not for sale directly)
        bool forSale;
        bool inAuction;
        uint256 auctionStartPrice;
        uint256 auctionEndTime;
        address highestBidder;
        uint256 highestBid;
        bool isListedForExhibition;
        bool isExhibited;
    }

    // Struct for auction details
    struct Auction {
        uint256 artworkId;
        uint256 startPrice;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }

    // Struct for exhibition proposals
    struct ExhibitionProposal {
        uint256 proposalId;
        uint256 artworkId;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isExecuted;
    }

    // Artist Reputation Data
    struct ArtistReputation {
        uint256 reputationScore;
        uint256 lastUpvoteTimestamp;
        uint256 lastDownvoteTimestamp;
    }

    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(uint256 => uint256) public artworkToProposalId; // Artwork ID to Proposal ID mapping
    mapping(address => bool) public isCurator;
    mapping(address => ArtistReputation) public artistReputations;
    mapping(uint256 => string) public artistTiers; // Tier index to tier name
    uint256[] public artistTierThresholds;        // Reputation thresholds for tiers

    uint256 public galleryCommissionFeePercentage = 5; // Default 5% commission
    uint256 public exhibitionProposalVoteDuration = 7 days; // Default vote duration
    uint256 public auctionDuration = 3 days; // Default auction duration
    uint256 public artistCooldownPeriod = 1 days; // Cooldown for artist reputation actions

    Counters.Counter private _proposalIds;
    Counters.Counter private _auctionCounter;

    event ArtworkMinted(uint256 artworkId, address artist, string artworkCID, string metadataCID);
    event ArtworkPriceSet(uint256 artworkId, uint256 price);
    event ArtworkListedForAuction(uint256 artworkId, uint256 startPrice, uint256 duration);
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 price);
    event ArtworkAuctionBidPlaced(uint256 artworkId, address bidder, uint256 bidAmount);
    event ArtworkAuctionFinalized(uint256 artworkId, address winner, uint256 finalPrice);
    event ArtworkExhibitionProposed(uint256 proposalId, uint256 artworkId, address proposer);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool vote);
    event ExhibitionProposalExecuted(uint256 proposalId, uint256 artworkId);
    event ArtistUpvoted(address artist, uint256 newReputation);
    event ArtistDownvoted(address artist, uint256 newReputation);
    event ArtworkReported(uint256 artworkId, address reporter, string reason);

    constructor() ERC721("Decentralized Autonomous Art Gallery", "DAAG") {
        _artworkIds.increment(); // Start artwork IDs from 1
    }

    // Modifier to check if an address is a curator
    modifier onlyCurator() {
        require(isCurator[msg.sender], "Only curators can perform this action");
        _;
    }

    // Modifier to check if the caller is the artwork owner
    modifier onlyArtworkOwner(uint256 _artworkId) {
        require(ownerOf(_artworkId) == msg.sender, "You are not the owner of this artwork");
        _;
    }

    // Modifier to check if artwork is listed for sale
    modifier artworkListedForSale(uint256 _artworkId) {
        require(artworks[_artworkId].forSale, "Artwork is not listed for sale directly");
        _;
    }

    // Modifier to check if artwork is in auction
    modifier artworkInAuction(uint256 _artworkId) {
        require(artworks[_artworkId].inAuction, "Artwork is not in auction");
        _;
    }

    // Modifier to check if auction is active
    modifier auctionActive(uint256 _auctionId) {
        require(auctions[_auctionId].isActive, "Auction is not active");
        require(block.timestamp < auctions[_auctionId].endTime, "Auction has ended");
        _;
    }

    // Modifier to prevent reputation manipulation too quickly
    modifier reputationCooldown(address _artist) {
        require(block.timestamp > artistReputations[_artist].lastUpvoteTimestamp + artistCooldownPeriod, "Reputation action cooldown not expired");
        require(block.timestamp > artistReputations[_artist].lastDownvoteTimestamp + artistCooldownPeriod, "Reputation action cooldown not expired");
        _;
    }


    // --------------------------------------------------
    // 1. Artwork Management Functions
    // --------------------------------------------------

    /**
     * @dev Mints a new artwork (NFT). Only callable by artists (in this simplified version, anyone can mint, but in a real scenario, you'd have artist registration).
     * @param _artworkCID CID of the artwork file (e.g., IPFS hash).
     * @param _metadataCID CID of the artwork metadata (e.g., IPFS hash).
     */
    function mintArtwork(string memory _artworkCID, string memory _metadataCID) public {
        _artworkIds.increment();
        uint256 artworkId = _artworkIds.current();

        _safeMint(msg.sender, artworkId);
        artworks[artworkId] = Artwork({
            artworkId: artworkId,
            artworkCID: _artworkCID,
            metadataCID: _metadataCID,
            artist: msg.sender,
            price: 0,
            forSale: false,
            inAuction: false,
            auctionStartPrice: 0,
            auctionEndTime: 0,
            highestBidder: address(0),
            highestBid: 0,
            isListedForExhibition: false,
            isExhibited: false
        });

        emit ArtworkMinted(artworkId, msg.sender, _artworkCID, _metadataCID);
    }

    /**
     * @dev Sets the price of an artwork for direct sale. Only callable by the artwork owner.
     * @param _artworkId ID of the artwork.
     * @param _price Price in wei.
     */
    function setArtworkPrice(uint256 _artworkId, uint256 _price) public onlyArtworkOwner(_artworkId) {
        require(!artworks[_artworkId].inAuction, "Cannot set price while artwork is in auction");
        artworks[_artworkId].price = _price;
        artworks[_artworkId].forSale = (_price > 0);
        emit ArtworkPriceSet(_artworkId, _price);
    }

    /**
     * @dev Lists an artwork for auction. Only callable by the artwork owner.
     * @param _artworkId ID of the artwork.
     * @param _startPrice Starting price for the auction in wei.
     * @param _duration Auction duration in seconds.
     */
    function listArtworkForAuction(uint256 _artworkId, uint256 _startPrice, uint256 _duration) public onlyArtworkOwner(_artworkId) {
        require(!artworks[_artworkId].forSale, "Artwork is already listed for direct sale. Cancel listing first.");
        require(!artworks[_artworkId].inAuction, "Artwork is already in auction.");
        require(_startPrice > 0, "Start price must be greater than 0");
        require(_duration > 0, "Auction duration must be greater than 0");

        artworks[_artworkId].inAuction = true;
        artworks[_artworkId].auctionStartPrice = _startPrice;
        artworks[_artworkId].auctionEndTime = block.timestamp + _duration;
        artworks[_artworkId].highestBid = _startPrice; // Initial bid is start price
        artworks[_artworkId].highestBidder = address(0); // No bidder initially

        emit ArtworkListedForAuction(_artworkId, _startPrice, _duration);
    }

    /**
     * @dev Cancels the direct sale or auction listing of an artwork. Only callable by the artwork owner.
     * @param _artworkId ID of the artwork.
     */
    function cancelArtworkListing(uint256 _artworkId) public onlyArtworkOwner(_artworkId) {
        artworks[_artworkId].forSale = false;
        artworks[_artworkId].inAuction = false;
        artworks[_artworkId].auctionEndTime = 0; // Reset auction end time
    }

    /**
     * @dev Allows an artist to burn their artwork (NFT) if it's not currently listed for sale or in auction.
     * @param _artworkId ID of the artwork to burn.
     */
    function burnArtwork(uint256 _artworkId) public onlyArtworkOwner(_artworkId) {
        require(!artworks[_artworkId].forSale, "Cannot burn artwork while it's listed for direct sale.");
        require(!artworks[_artworkId].inAuction, "Cannot burn artwork while it's in auction.");
        require(!artworks[_artworkId].isExhibited, "Cannot burn artwork while it is being exhibited.");

        _burn(_artworkId);
        delete artworks[_artworkId]; // Remove artwork from mapping
    }

    /**
     * @dev Transfers ownership of an artwork to another address. Standard ERC721 transfer.
     * @param _artworkId ID of the artwork.
     * @param _to Address to transfer ownership to.
     */
    function transferArtworkOwnership(uint256 _artworkId, address _to) public onlyArtworkOwner(_artworkId) {
        transferFrom(msg.sender, _to, _artworkId);
    }

    /**
     * @dev Gets detailed information about a specific artwork.
     * @param _artworkId ID of the artwork.
     * @return Artwork struct containing artwork details.
     */
    function getArtworkDetails(uint256 _artworkId) public view returns (Artwork memory) {
        return artworks[_artworkId];
    }

    /**
     * @dev Gets a list of artwork IDs owned by a specific artist.
     * @param _artist Address of the artist.
     * @return Array of artwork IDs.
     */
    function getArtistArtworks(address _artist) public view returns (uint256[] memory) {
        uint256[] memory artistArtworks = new uint256[](balanceOf(_artist));
        uint256 count = 0;
        for (uint256 i = 1; i <= _artworkIds.current(); i++) {
            try {
                if (ownerOf(i) == _artist) {
                    artistArtworks[count] = i;
                    count++;
                }
            } catch (bytes memory reason) {
                // artworkId does not exist (e.g., burned), skip
            }
        }
        return artistArtworks;
    }


    // --------------------------------------------------
    // 2. Gallery Management & Curation Functions
    // --------------------------------------------------

    /**
     * @dev Allows curators to propose an artwork for a virtual exhibition.
     * @param _artworkId ID of the artwork to propose.
     */
    function proposeArtworkForExhibition(uint256 _artworkId) public onlyCurator {
        require(!artworks[_artworkId].isExhibited, "Artwork is already exhibited.");
        require(!artworks[_artworkId].isListedForExhibition, "Artwork is already proposed for exhibition.");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        exhibitionProposals[proposalId] = ExhibitionProposal({
            proposalId: proposalId,
            artworkId: _artworkId,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isExecuted: false
        });
        artworkToProposalId[_artworkId] = proposalId;
        artworks[_artworkId].isListedForExhibition = true;

        emit ArtworkExhibitionProposed(proposalId, _artworkId, msg.sender);
    }

    /**
     * @dev Allows gallery members/token holders to vote on exhibition proposals. (Simplified voting - in a real DAO, you'd have token-weighted voting).
     * @param _proposalId ID of the exhibition proposal.
     * @param _vote True for vote in favor, false for vote against.
     */
    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) public {
        require(exhibitionProposals[_proposalId].isActive, "Proposal is not active");
        require(!exhibitionProposals[_proposalId].isExecuted, "Proposal is already executed");
        require(block.timestamp < block.timestamp + exhibitionProposalVoteDuration, "Voting period has ended"); // Simplified duration check

        if (_vote) {
            exhibitionProposals[_proposalId].votesFor++;
        } else {
            exhibitionProposals[_proposalId].votesAgainst++;
        }
        emit ExhibitionProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes an approved exhibition proposal if enough votes are received (simplified approval logic).
     * @param _proposalId ID of the exhibition proposal.
     */
    function executeExhibitionProposal(uint256 _proposalId) public onlyCurator {
        require(exhibitionProposals[_proposalId].isActive, "Proposal is not active");
        require(!exhibitionProposals[_proposalId].isExecuted, "Proposal is already executed");
        require(block.timestamp > block.timestamp + exhibitionProposalVoteDuration, "Voting period has not ended yet"); // Simplified duration check
        require(exhibitionProposals[_proposalId].votesFor > exhibitionProposals[_proposalId].votesAgainst, "Proposal not approved by majority vote"); // Simplified majority vote

        exhibitionProposals[_proposalId].isActive = false;
        exhibitionProposals[_proposalId].isExecuted = true;
        artworks[exhibitionProposals[_proposalId].artworkId].isExhibited = true;

        emit ExhibitionProposalExecuted(_proposalId, exhibitionProposals[_proposalId].artworkId);
    }

    /**
     * @dev Adds a new curator. Only callable by the contract owner.
     * @param _curator Address of the curator to add.
     */
    function addCurator(address _curator) public onlyOwner {
        isCurator[_curator] = true;
    }

    /**
     * @dev Removes a curator. Only callable by the contract owner.
     * @param _curator Address of the curator to remove.
     */
    function removeCurator(address _curator) public onlyOwner {
        isCurator[_curator] = false;
    }

    /**
     * @dev Sets the gallery commission fee percentage. Only callable by the contract owner.
     * @param _feePercentage Commission percentage (e.g., 5 for 5%).
     */
    function setGalleryCommissionFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Commission fee cannot exceed 100%");
        galleryCommissionFeePercentage = _feePercentage;
    }


    // --------------------------------------------------
    // 3. Marketplace & Sales Functions
    // --------------------------------------------------

    /**
     * @dev Allows users to purchase artworks listed for direct sale.
     * @param _artworkId ID of the artwork to purchase.
     */
    function purchaseArtwork(uint256 _artworkId) public payable artworkListedForSale(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(msg.value >= artwork.price, "Insufficient funds sent");

        uint256 commission = artwork.price.mul(galleryCommissionFeePercentage).div(100);
        uint256 artistEarnings = artwork.price.sub(commission);

        // Transfer commission to gallery contract
        payable(owner()).transfer(commission);

        // Transfer earnings to artist
        payable(artwork.artist).transfer(artistEarnings);

        // Transfer NFT to buyer
        transferArtworkOwnership(_artworkId, msg.sender);

        // Reset sale flags
        artwork.forSale = false;
        artwork.price = 0;

        emit ArtworkPurchased(_artworkId, msg.sender, artwork.price);

        // Refund any extra amount sent
        if (msg.value > artwork.price) {
            payable(msg.sender).transfer(msg.value - artwork.price);
        }
    }

    /**
     * @dev Allows users to place bids on artworks in auction.
     * @param _artworkId ID of the artwork in auction.
     */
    function bidOnArtworkAuction(uint256 _artworkId) public payable artworkInAuction(_artworkId) {
        Auction storage auction = auctions[_auctionCounter.current()]; // Assuming auction counter tracks current auction ID - needs refinement in real scenario.
        Artwork storage artwork = artworks[_artworkId];

        require(block.timestamp < artwork.auctionEndTime, "Auction has ended");
        require(msg.value > artwork.highestBid, "Bid amount must be higher than the current highest bid");

        // Refund previous highest bidder (if any)
        if (artwork.highestBidder != address(0)) {
            payable(artwork.highestBidder).transfer(artwork.highestBid);
        }

        artwork.highestBidder = msg.sender;
        artwork.highestBid = msg.value;
        emit ArtworkAuctionBidPlaced(_artworkId, msg.sender, msg.value);
    }


    /**
     * @dev Finalizes an artwork auction after its duration ends, distributing funds.
     * @param _artworkId ID of the artwork auction to finalize.
     */
    function finalizeArtworkAuction(uint256 _artworkId) public artworkInAuction(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(block.timestamp >= artwork.auctionEndTime, "Auction is not yet finished");
        require(artwork.inAuction, "Artwork is not in auction");

        artwork.inAuction = false; // Mark auction as finished

        uint256 finalPrice = artwork.highestBid;
        address winner = artwork.highestBidder;

        uint256 commission = finalPrice.mul(galleryCommissionFeePercentage).div(100);
        uint256 artistEarnings = finalPrice.sub(commission);

        // Transfer commission to gallery contract
        payable(owner()).transfer(commission);

        // Transfer earnings to artist
        payable(artwork.artist).transfer(artistEarnings);

        // Transfer NFT to winner
        if (winner != address(0)) {
            transferArtworkOwnership(_artworkId, winner);
        } else {
            // No bids placed, return artwork to artist (optional - could also keep in gallery or have different handling)
            transferArtworkOwnership(_artworkId, artwork.artist);
        }

        emit ArtworkAuctionFinalized(_artworkId, winner, finalPrice);
    }


    /**
     * @dev Allows artists to withdraw their earnings from artwork sales.
     */
    function withdrawArtistEarnings() public {
        // In a real system, you would track artist balances and allow withdrawal based on that.
        // This simplified version just allows withdrawing the contract balance (minus gallery commission).
        uint256 artistBalance = address(this).balance; // Simplification for example - needs proper accounting
        uint256 commissionEstimate = artistBalance.mul(galleryCommissionFeePercentage).div(100);
        uint256 withdrawableAmount = artistBalance.sub(commissionEstimate);

        require(withdrawableAmount > 0, "No earnings to withdraw.");
        payable(msg.sender).transfer(withdrawableAmount);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated gallery commission fees.
     */
    function withdrawGalleryCommission() public onlyOwner {
        uint256 galleryBalance = address(this).balance;
        require(galleryBalance > 0, "No gallery commission to withdraw.");
        payable(owner()).transfer(galleryBalance);
    }


    // --------------------------------------------------
    // 4. Reputation & Artist Tiers Functions
    // --------------------------------------------------

    /**
     * @dev Allows users to report artworks for policy violations.
     * @param _artworkId ID of the artwork being reported.
     * @param _reason Reason for reporting.
     */
    function reportArtwork(uint256 _artworkId, string memory _reason) public {
        // In a real system, this would trigger moderation workflows, potentially involving curators/admins.
        emit ArtworkReported(_artworkId, msg.sender, _reason);
        // Further actions (e.g., flagging, review) would be implemented off-chain or in more complex contract logic.
    }

    /**
     * @dev Allows users to upvote an artist, increasing their reputation score.
     * @param _artist Address of the artist to upvote.
     */
    function upvoteArtist(address _artist) public reputationCooldown(_artist) {
        artistReputations[_artist].reputationScore++;
        artistReputations[_artist].lastUpvoteTimestamp = block.timestamp;
        emit ArtistUpvoted(_artist, artistReputations[_artist].reputationScore);
    }

    /**
     * @dev Allows users to downvote an artist, potentially decreasing their reputation score.
     * @param _artist Address of the artist to downvote.
     */
    function downvoteArtist(address _artist) public reputationCooldown(_artist) {
        if (artistReputations[_artist].reputationScore > 0) {
            artistReputations[_artist].reputationScore--;
        }
        artistReputations[_artist].lastDownvoteTimestamp = block.timestamp;
        emit ArtistDownvoted(_artist, artistReputations[_artist].reputationScore);
    }

    /**
     * @dev Gets the reputation score of an artist.
     * @param _artist Address of the artist.
     * @return Reputation score.
     */
    function getArtistReputation(address _artist) public view returns (uint256) {
        return artistReputations[_artist].reputationScore;
    }

    /**
     * @dev Sets the thresholds and names for artist reputation tiers. Only callable by the contract owner.
     * @param _thresholds Array of reputation thresholds (e.g., [10, 50, 100]).
     * @param _tierNames Array of tier names corresponding to thresholds (e.g., ["Bronze", "Silver", "Gold", "Platinum"]).
     */
    function setArtistTierThresholds(uint256[] memory _thresholds, string[] memory _tierNames) public onlyOwner {
        require(_thresholds.length == _tierNames.length, "Thresholds and tier names arrays must have the same length.");
        artistTierThresholds = _thresholds;
        for (uint256 i = 0; i < _tierNames.length; i++) {
            artistTiers[i] = _tierNames[i];
        }
    }

    /**
     * @dev Gets the tier of an artist based on their reputation score and defined thresholds.
     * @param _artist Address of the artist.
     * @return Tier name (string). Returns "Unranked" if below the lowest threshold.
     */
    function getArtistTier(address _artist) public view returns (string memory) {
        uint256 reputation = artistReputations[_artist].reputationScore;
        for (uint256 i = artistTierThresholds.length; i > 0; i--) {
            if (reputation >= artistTierThresholds[i - 1]) {
                return artistTiers[i - 1];
            }
        }
        return "Unranked"; // Below lowest tier
    }


    // --------------------------------------------------
    // 5. Utility & View Functions
    // --------------------------------------------------

    /**
     * @dev Gets the current balance of the gallery contract.
     * @return Contract balance in wei.
     */
    function getGalleryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Checks if an artwork is currently listed for direct sale.
     * @param _artworkId ID of the artwork.
     * @return True if listed for sale, false otherwise.
     */
    function isArtworkListedForSale(uint256 _artworkId) public view returns (bool) {
        return artworks[_artworkId].forSale;
    }

    /**
     * @dev Checks if an artwork is currently in auction.
     * @param _artworkId ID of the artwork.
     * @return True if in auction, false otherwise.
     */
    function isArtworkInAuction(uint256 _artworkId) public view returns (bool) {
        return artworks[_artworkId].inAuction;
    }

    /**
     * @dev Checks if an address is a registered curator.
     * @param _account Address to check.
     * @return True if curator, false otherwise.
     */
    function isCurator(address _account) public view returns (bool) {
        return isCurator[_account];
    }

    /**
     * @dev Gets the current gallery commission fee percentage.
     * @return Commission fee percentage.
     */
    function getGalleryCommissionFee() public view returns (uint256) {
        return galleryCommissionFeePercentage;
    }
}
```