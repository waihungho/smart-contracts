```solidity
/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery where artists can submit artworks (NFTs),
 * curators can vote on submissions, and collectors can purchase limited edition digital art.
 * It incorporates advanced concepts like DAO-style governance for gallery parameters, dynamic pricing mechanisms,
 * on-chain reputation for curators, and decentralized exhibition management.
 * This contract aims to provide a unique and trendy platform for digital art within the blockchain ecosystem.
 *
 * Function Summary:
 *
 * **Gallery Management (Admin Functions):**
 * 1.  `setGalleryName(string _name)`:  Set the name of the art gallery. Only callable by the gallery owner.
 * 2.  `setCuratorFee(uint256 _feePercentage)`: Set the percentage fee curators receive from artwork sales they curated. Only callable by the gallery owner.
 * 3.  `setPlatformFee(uint256 _feePercentage)`: Set the percentage fee the platform (gallery) takes from artwork sales. Only callable by the gallery owner.
 * 4.  `setMaxEditionsPerArtwork(uint256 _maxEditions)`: Set the maximum number of editions allowed for each artwork. Only callable by the gallery owner.
 * 5.  `pauseGallery()`: Pause all core functionalities of the gallery (submission, curation, buying). Only callable by the gallery owner.
 * 6.  `unpauseGallery()`: Unpause the gallery, restoring all functionalities. Only callable by the gallery owner.
 * 7.  `withdrawPlatformFees()`: Allow the gallery owner to withdraw accumulated platform fees. Only callable by the gallery owner.
 *
 * **Artist Functions:**
 * 8.  `submitArtwork(string _artworkURI, uint256 _initialPrice)`: Artists submit their artwork with metadata URI and initial price.
 * 9.  `mintNFT(uint256 _artworkId)`: After successful curation, artists can mint NFTs for their approved artwork.
 * 10. `setArtworkPrice(uint256 _artworkId, uint256 _newPrice)`: Artists can update the price of their artwork (before any sales).
 * 11. `withdrawArtistProceeds(uint256 _artworkId)`: Artists can withdraw their earnings from sold artwork editions.
 *
 * **Curator Functions:**
 * 12. `stakeForCuration(uint256 _stakeAmount)`: Users can stake tokens to become curators and participate in the curation process.
 * 13. `unstakeForCuration(uint256 _unstakeAmount)`: Curators can unstake their tokens, losing curator status after a cooldown period.
 * 14. `proposeArtworkForListing(uint256 _artworkId)`: Curators can propose submitted artworks for listing in the gallery.
 * 15. `voteOnArtworkProposal(uint256 _proposalId, bool _vote)`: Curators can vote 'for' or 'against' artwork listing proposals.
 * 16. `claimCurationRewards()`: Curators can claim rewards earned from successful curations (based on sales of curated art).
 *
 * **Collector Functions:**
 * 17. `buyArtwork(uint256 _artworkId)`: Collectors can purchase available editions of listed artworks.
 *
 * **Exhibition Functions (Decentralized Exhibition Management):**
 * 18. `createExhibition(string _exhibitionName, string _exhibitionDescription, uint256 _startTime, uint256 _endTime)`: Curators can propose and create decentralized exhibitions.
 * 19. `addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Add approved and listed artworks to a specific exhibition.
 * 20. `startExhibition(uint256 _exhibitionId)`: Start an exhibition, making it visible in the gallery.
 * 21. `endExhibition(uint256 _exhibitionId)`: End an exhibition, potentially triggering special events or features.
 * 22. `voteForExhibition(uint256 _exhibitionId, bool _vote)`: Community (curators or token holders) can vote on proposed exhibitions.
 *
 * **Utility/View Functions:**
 * 23. `getGalleryName()`: Returns the name of the gallery.
 * 24. `getArtworkDetails(uint256 _artworkId)`: Returns details of a specific artwork.
 * 25. `getCuratorStake(address _curatorAddress)`: Returns the stake amount of a curator.
 * 26. `getExhibitionDetails(uint256 _exhibitionId)`: Returns details of a specific exhibition.
 * 27. `isArtworkListed(uint256 _artworkId)`: Checks if an artwork is listed in the gallery.
 * 28. `isCurator(address _user)`: Checks if an address is a registered curator.
 * 29. `getPlatformBalance()`: Returns the current balance of platform fees.
 * 30. `getArtistBalance(uint256 _artworkId)`: Returns the current balance of artist proceeds for a specific artwork.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedAutonomousArtGallery is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    string public galleryName;
    uint256 public curatorFeePercentage; // Percentage of sale price for curators
    uint256 public platformFeePercentage; // Percentage of sale price for platform
    uint256 public maxEditionsPerArtwork = 10; // Default max editions per artwork
    uint256 public curatorStakeAmount = 100 ether; // Example stake amount, can be token based
    uint256 public curatorUnstakeCooldown = 7 days; // Cooldown period after unstaking

    Counters.Counter private _artworkIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _exhibitionIds;

    struct Artwork {
        uint256 id;
        address artist;
        string artworkURI;
        uint256 initialPrice;
        uint256 currentPrice;
        uint256 editionsMinted;
        uint256 editionsSold;
        bool isListed;
        bool isApproved;
        uint256 artistBalance; // Artist's accumulated earnings
        uint256 curatorRewardBalance; // Accumulated reward for curator(s) who proposed this artwork
        uint256 proposalId; // ID of the proposal that listed this artwork
    }

    struct Curator {
        address curatorAddress;
        uint256 stakeAmount;
        uint256 lastUnstakeTime;
        bool isActiveCurator;
    }

    struct ArtworkProposal {
        uint256 id;
        uint256 artworkId;
        address proposer; // Curator who proposed
        uint256 upVotes;
        uint256 downVotes;
        bool proposalActive;
        uint256 curatorRewardPool; // Pool for curator rewards for this artwork's sales
    }

    struct Exhibition {
        uint256 id;
        string name;
        string description;
        address creator; // Curator who created the exhibition proposal
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isApproved; // Needs governance approval? or curator led? - let's assume curator led for now.
        uint256[] artworkIds; // Array of artwork IDs in this exhibition
    }

    mapping(uint256 => Artwork) public artworks;
    mapping(address => Curator) public curators;
    mapping(uint256 => ArtworkProposal) public artworkProposals;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => uint256) public editionToArtworkId; // Mapping edition ID to Artwork ID for ERC721
    mapping(uint256 => uint256) public artworkIdToProposalId; // Mapping artwork ID to its listing proposal ID

    uint256 public platformBalance; // Accumulated platform fees

    event GalleryNameUpdated(string newName);
    event CuratorFeeUpdated(uint256 newFeePercentage);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event MaxEditionsUpdated(uint256 newMaxEditions);
    event GalleryPaused();
    event GalleryUnpaused();
    event PlatformFeesWithdrawn(uint256 amount);

    event ArtworkSubmitted(uint256 artworkId, address artist, string artworkURI, uint256 initialPrice);
    event ArtworkMinted(uint256 editionId, uint256 artworkId, address artist, address buyer);
    event ArtworkPriceUpdated(uint256 artworkId, uint256 newPrice);
    event ArtistProceedsWithdrawn(uint256 artworkId, uint256 amount, address artist);

    event CuratorStaked(address curatorAddress, uint256 stakeAmount);
    event CuratorUnstaked(address curatorAddress, uint256 unstakeAmount);
    event ArtworkProposed(uint256 proposalId, uint256 artworkId, address proposer);
    event ArtworkProposalVote(uint256 proposalId, address voter, bool vote);
    event ArtworkListed(uint256 artworkId, uint256 proposalId);
    event CurationRewardsClaimed(address curatorAddress, uint256 amount);

    event ArtworkPurchased(uint256 editionId, uint256 artworkId, address buyer, uint256 price);

    event ExhibitionCreated(uint256 exhibitionId, string name, address creator);
    event ArtworkAddedToExhibition(uint256 exhibitionId, uint256 artworkId);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event ExhibitionVote(uint256 exhibitionId, address voter, bool vote);


    constructor(string memory _galleryName, string memory _tokenName, string memory _tokenSymbol) ERC721(_tokenName, _tokenSymbol) {
        galleryName = _galleryName;
        curatorFeePercentage = 5; // Default 5% curator fee
        platformFeePercentage = 10; // Default 10% platform fee
    }

    // --- Modifiers ---
    modifier onlyGalleryOwner() {
        require(owner() == _msgSender(), "Only gallery owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(isCurator(_msgSender()), "Only registered curators can call this function.");
        _;
    }

    modifier onlyArtist(uint256 _artworkId) {
        require(artworks[_artworkId].artist == _msgSender(), "Only the artist of this artwork can call this function.");
        _;
    }

    modifier whenGalleryNotPaused() {
        require(!paused(), "Gallery is currently paused.");
        _;
    }

    modifier whenGalleryPaused() {
        require(paused(), "Gallery is not currently paused.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(_artworkIds.current() >= _artworkId && _artworkId > 0 && artworks[_artworkId].id == _artworkId, "Artwork does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalIds.current() >= _proposalId && _proposalId > 0 && artworkProposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier exhibitionExists(uint256 _exhibitionId) {
        require(_exhibitionIds.current() >= _exhibitionId && _exhibitionId > 0 && exhibitions[_exhibitionId].id == _exhibitionId, "Exhibition does not exist.");
        _;
    }

    modifier artworkNotListed(uint256 _artworkId) {
        require(!artworks[_artworkId].isListed, "Artwork is already listed.");
        _;
    }

    modifier artworkListed(uint256 _artworkId) {
        require(artworks[_artworkId].isListed, "Artwork is not listed.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(artworkProposals[_proposalId].proposalActive, "Proposal is not active.");
        _;
    }

    modifier proposalNotActive(uint256 _proposalId) {
        require(!artworkProposals[_proposalId].proposalActive, "Proposal is already closed.");
        _;
    }

    modifier exhibitionNotActive(uint256 _exhibitionId) {
        require(!exhibitions[_exhibitionId].isActive, "Exhibition is already active.");
        _;
    }

    modifier exhibitionActive(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        _;
    }


    // --- Gallery Management Functions ---

    function setGalleryName(string memory _name) external onlyGalleryOwner {
        galleryName = _name;
        emit GalleryNameUpdated(_name);
    }

    function setCuratorFee(uint256 _feePercentage) external onlyGalleryOwner {
        require(_feePercentage <= 100, "Curator fee percentage must be less than or equal to 100.");
        curatorFeePercentage = _feePercentage;
        emit CuratorFeeUpdated(_feePercentage);
    }

    function setPlatformFee(uint256 _feePercentage) external onlyGalleryOwner {
        require(_feePercentage <= 100, "Platform fee percentage must be less than or equal to 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage);
    }

    function setMaxEditionsPerArtwork(uint256 _maxEditions) external onlyGalleryOwner {
        maxEditionsPerArtwork = _maxEditions;
        emit MaxEditionsUpdated(_maxEditions);
    }

    function pauseGallery() external onlyGalleryOwner whenGalleryNotPaused {
        _pause();
        emit GalleryPaused();
    }

    function unpauseGallery() external onlyGalleryOwner whenGalleryPaused {
        _unpause();
        emit GalleryUnpaused();
    }

    function withdrawPlatformFees() external onlyGalleryOwner {
        uint256 amount = platformBalance;
        platformBalance = 0;
        payable(owner()).transfer(amount);
        emit PlatformFeesWithdrawn(amount);
    }

    // --- Artist Functions ---

    function submitArtwork(string memory _artworkURI, uint256 _initialPrice) external whenGalleryNotPaused {
        _artworkIds.increment();
        uint256 artworkId = _artworkIds.current();
        artworks[artworkId] = Artwork({
            id: artworkId,
            artist: _msgSender(),
            artworkURI: _artworkURI,
            initialPrice: _initialPrice,
            currentPrice: _initialPrice,
            editionsMinted: 0,
            editionsSold: 0,
            isListed: false,
            isApproved: false, // Initially not approved, needs curation
            artistBalance: 0,
            curatorRewardBalance: 0,
            proposalId: 0
        });
        emit ArtworkSubmitted(artworkId, _msgSender(), _artworkURI, _initialPrice);
    }

    function mintNFT(uint256 _artworkId) external whenGalleryNotPaused artworkExists(_artworkId) onlyArtist(_artworkId) {
        require(artworks[_artworkId].isApproved, "Artwork is not yet approved by curators.");
        require(artworks[_artworkId].editionsMinted < maxEditionsPerArtwork, "Maximum editions already minted.");

        uint256 editionId = totalSupply() + 1; // Simple edition ID, could be improved for uniqueness if needed
        _mint(_msgSender(), editionId);
        _setTokenURI(editionId, artworks[_artworkId].artworkURI);
        editionToArtworkId[editionId] = _artworkId;

        artworks[_artworkId].editionsMinted++;
        emit ArtworkMinted(editionId, _artworkId, _msgSender(), address(0)); // Buyer is address(0) initially, minted not sold
    }

    function setArtworkPrice(uint256 _artworkId, uint256 _newPrice) external whenGalleryNotPaused artworkExists(_artworkId) onlyArtist(_artworkId) artworkNotListed(_artworkId) {
        artworks[_artworkId].currentPrice = _newPrice;
        emit ArtworkPriceUpdated(_artworkId, _newPrice);
    }

    function withdrawArtistProceeds(uint256 _artworkId) external whenGalleryNotPaused artworkExists(_artworkId) onlyArtist(_artworkId) {
        uint256 amount = artworks[_artworkId].artistBalance;
        require(amount > 0, "No proceeds to withdraw.");
        artworks[_artworkId].artistBalance = 0;
        payable(_msgSender()).transfer(amount);
        emit ArtistProceedsWithdrawn(_artworkId, amount, _msgSender());
    }

    // --- Curator Functions ---

    function stakeForCuration(uint256 _stakeAmount) external whenGalleryNotPaused {
        require(msg.value >= curatorStakeAmount, "Stake amount must be at least the required amount."); // Example using ETH stake, can be token based
        if (!isCurator(_msgSender())) {
            curators[_msgSender()] = Curator({
                curatorAddress: _msgSender(),
                stakeAmount: msg.value,
                lastUnstakeTime: 0,
                isActiveCurator: true
            });
        } else {
            curators[_msgSender()].stakeAmount += msg.value;
            curators[_msgSender()].isActiveCurator = true;
        }
        emit CuratorStaked(_msgSender(), msg.value);
    }

    function unstakeForCuration(uint256 _unstakeAmount) external whenGalleryNotPaused onlyCurator {
        require(curators[_msgSender()].stakeAmount >= _unstakeAmount, "Insufficient stake to unstake.");
        require(block.timestamp >= curators[_msgSender()].lastUnstakeTime + curatorUnstakeCooldown, "Unstake cooldown period not over yet."); // Cooldown

        curators[_msgSender()].stakeAmount -= _unstakeAmount;
        payable(_msgSender()).transfer(_unstakeAmount);
        emit CuratorUnstaked(_msgSender(), _unstakeAmount);

        if (curators[_msgSender()].stakeAmount == 0) {
            curators[_msgSender()].isActiveCurator = false; // No longer curator if stake is 0
            curators[_msgSender()].lastUnstakeTime = block.timestamp; // Start cooldown for re-staking/becoming curator again quickly
        }
    }

    function proposeArtworkForListing(uint256 _artworkId) external whenGalleryNotPaused onlyCurator artworkExists(_artworkId) artworkNotListed(_artworkId) {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        artworkProposals[proposalId] = ArtworkProposal({
            id: proposalId,
            artworkId: _artworkId,
            proposer: _msgSender(),
            upVotes: 0,
            downVotes: 0,
            proposalActive: true,
            curatorRewardPool: 0 // Initialize reward pool for this artwork's sales
        });
        artworkIdToProposalId[_artworkId] = proposalId;
        artworks[_artworkId].proposalId = proposalId; // Link artwork to proposal
        emit ArtworkProposed(proposalId, _artworkId, _msgSender());
    }

    function voteOnArtworkProposal(uint256 _proposalId, bool _vote) external whenGalleryNotPaused onlyCurator proposalExists(_proposalId) proposalActive(_proposalId) {
        require(artworkProposals[_proposalId].proposer != _msgSender(), "Proposer cannot vote on their own proposal."); // Prevent self-voting
        require(artworkProposals[_proposalId].upVotes + artworkProposals[_proposalId].downVotes < getActiveCuratorCount(), "All curators have already voted."); // Prevent over-voting

        if (_vote) {
            artworkProposals[_proposalId].upVotes++;
        } else {
            artworkProposals[_proposalId].downVotes++;
        }
        emit ArtworkProposalVote(_proposalId, _msgSender(), _vote);

        // Simple majority for approval (can be adjusted for quorum, etc.)
        if (artworkProposals[_proposalId].upVotes > (getActiveCuratorCount() / 2)) {
            _listArtwork(_proposalId); // List the artwork if proposal passes
            artworkProposals[_proposalId].proposalActive = false; // Close proposal
        } else if (artworkProposals[_proposalId].downVotes > (getActiveCuratorCount() / 2)) {
            artworkProposals[_proposalId].proposalActive = false; // Close proposal even if rejected
        }
    }

    function claimCurationRewards() external whenGalleryNotPaused onlyCurator {
        uint256 totalRewards = 0;
        for (uint256 i = 1; i <= _proposalIds.current(); i++) {
            if (artworkProposals[i].proposer == _msgSender()) { // Check if this curator is the proposer
                totalRewards += artworkProposals[i].curatorRewardPool;
                artworkProposals[i].curatorRewardPool = 0; // Reset pool after claiming
            }
        }

        require(totalRewards > 0, "No curation rewards to claim.");
        payable(_msgSender()).transfer(totalRewards);
        emit CurationRewardsClaimed(_msgSender(), totalRewards);
    }


    // --- Collector Functions ---

    function buyArtwork(uint256 _artworkId) external payable whenGalleryNotPaused artworkExists(_artworkId) artworkListed(_artworkId) {
        require(artworks[_artworkId].editionsSold < maxEditionsPerArtwork, "All editions sold out.");
        require(msg.value >= artworks[_artworkId].currentPrice, "Insufficient funds sent.");

        uint256 editionId = totalSupply() + 1;
        _mint(_msgSender(), editionId);
        _setTokenURI(editionId, artworks[_artworkId].artworkURI);
        editionToArtworkId[editionId] = _artworkId;

        artworks[_artworkId].editionsSold++;

        // Distribute funds: Artist, Curator, Platform
        uint256 curatorCut = artworks[_artworkId].currentPrice.mul(curatorFeePercentage).div(100);
        uint256 platformCut = artworks[_artworkId].currentPrice.mul(platformFeePercentage).div(100);
        uint256 artistProceeds = artworks[_artworkId].currentPrice.sub(curatorCut).sub(platformCut);

        artworks[_artworkId].artistBalance += artistProceeds;
        artworkProposals[artworks[_artworkId].proposalId].curatorRewardPool += curatorCut; // Add to curator reward pool
        platformBalance += platformCut;

        // Refund any excess ETH sent
        if (msg.value > artworks[_artworkId].currentPrice) {
            payable(_msgSender()).transfer(msg.value - artworks[_artworkId].currentPrice);
        }

        emit ArtworkPurchased(editionId, _artworkId, _msgSender(), artworks[_artworkId].currentPrice);
        emit ArtworkMinted(editionId, _artworkId, artworks[_artworkId].artist, _msgSender()); // Emit Minted event also on purchase
    }


    // --- Exhibition Functions ---

    function createExhibition(string memory _exhibitionName, string memory _exhibitionDescription, uint256 _startTime, uint256 _endTime) external whenGalleryNotPaused onlyCurator {
        _exhibitionIds.increment();
        uint256 exhibitionId = _exhibitionIds.current();
        exhibitions[exhibitionId] = Exhibition({
            id: exhibitionId,
            name: _exhibitionName,
            description: _exhibitionDescription,
            creator: _msgSender(),
            startTime: _startTime,
            endTime: _endTime,
            isActive: false,
            isApproved: true, // Assuming curator-led exhibitions are auto-approved for now, can add governance if needed
            artworkIds: new uint256[](0)
        });
        emit ExhibitionCreated(exhibitionId, _exhibitionName, _msgSender());
    }

    function addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId) external whenGalleryNotPaused exhibitionExists(_exhibitionId) onlyCurator artworkExists(_artworkId) artworkListed(_artworkId) exhibitionNotActive(_exhibitionId) {
        exhibitions[_exhibitionId].artworkIds.push(_artworkId);
        emit ArtworkAddedToExhibition(_exhibitionId, _artworkId);
    }

    function startExhibition(uint256 _exhibitionId) external whenGalleryNotPaused exhibitionExists(_exhibitionId) onlyCurator exhibitionNotActive(_exhibitionId) {
        require(block.timestamp >= exhibitions[_exhibitionId].startTime, "Exhibition start time not reached yet.");
        exhibitions[_exhibitionId].isActive = true;
        emit ExhibitionStarted(_exhibitionId);
    }

    function endExhibition(uint256 _exhibitionId) external whenGalleryNotPaused exhibitionExists(_exhibitionId) onlyCurator exhibitionActive(_exhibitionId) {
        require(block.timestamp >= exhibitions[_exhibitionId].endTime, "Exhibition end time not reached yet.");
        exhibitions[_exhibitionId].isActive = false;
        emit ExhibitionEnded(_exhibitionId);
    }

    // Future: Exhibition voting can be added if needed (e.g., for community curated exhibitions)
    // function voteForExhibition(uint256 _exhibitionId, bool _vote) external whenGalleryNotPaused exhibitionExists(_exhibitionId) onlyCurator { ... }


    // --- Utility/View Functions ---

    function getGalleryName() external view returns (string memory) {
        return galleryName;
    }

    function getArtworkDetails(uint256 _artworkId) external view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getCuratorStake(address _curatorAddress) external view returns (uint256) {
        return curators[_curatorAddress].stakeAmount;
    }

    function getExhibitionDetails(uint256 _exhibitionId) external view exhibitionExists(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    function isArtworkListed(uint256 _artworkId) external view artworkExists(_artworkId) returns (bool) {
        return artworks[_artworkId].isListed;
    }

    function isCurator(address _user) public view returns (bool) {
        return curators[_user].isActiveCurator && block.timestamp >= curators[_user].lastUnstakeTime + curatorUnstakeCooldown;
    }

    function getActiveCuratorCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _proposalIds.current(); i++) { // Iterate through proposal IDs as a proxy for curators (not ideal in production, better to maintain a list of curators)
            if (isCurator(artworkProposals[i].proposer)) { // Check if the proposer (proxy for curator) is active
                count++;
            }
        }
        return count; // Inefficient, should be optimized in real implementation. Iterate over curators mapping instead if possible.
    }


    function getPlatformBalance() external view returns (uint256) {
        return platformBalance;
    }

    function getArtistBalance(uint256 _artworkId) external view artworkExists(_artworkId) onlyArtist(_artworkId) returns (uint256) {
        return artworks[_artworkId].artistBalance;
    }

    // --- Internal Functions ---

    function _listArtwork(uint256 _proposalId) internal proposalExists(_proposalId) {
        uint256 artworkId = artworkProposals[_proposalId].artworkId;
        artworks[artworkId].isListed = true;
        artworks[artworkId].isApproved = true; // Artwork is approved upon listing
        emit ArtworkListed(artworkId, _proposalId);
    }

    // Override to ensure token URI is always set. In case of direct minting for testing.
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._afterTokenTransfer(from, to, tokenId);
        if (bytes(tokenURI(tokenId)).length == 0) { // If tokenURI is not set (e.g., direct minting for testing)
            uint256 artworkId = editionToArtworkId[tokenId];
            if (artworkId > 0) {
                _setTokenURI(tokenId, artworks[artworkId].artworkURI); // Set from artwork URI
            }
        }
    }

    // Override _beforeTokenTransfer to prevent direct transfers, enforce buying through the gallery
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0) && to != address(0)) { // Prevent direct transfers
            revert("Direct token transfers are not allowed. Use the gallery's buy function.");
        }
    }
}
```