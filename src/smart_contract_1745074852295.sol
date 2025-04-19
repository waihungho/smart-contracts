```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Art Marketplace with Generative Traits and Community Evolution
 * @author Bard (Example Smart Contract - Educational Purpose)
 * @dev This smart contract implements a dynamic NFT marketplace where digital art pieces have generative traits that can evolve based on community votes and on-chain events.
 * It includes advanced features like dynamic metadata, community governance of art evolution, auctions, staking for voting power, and decentralized artist revenue sharing.
 *
 * **Outline:**
 * 1. **NFT Core (DynamicArtToken):** ERC721 compliant NFT with dynamic metadata and generative traits.
 * 2. **Marketplace (ArtMarketplace):** Functionality for listing, buying, selling, and auctioning dynamic NFTs.
 * 3. **Dynamic Trait Evolution (TraitEvolution):** Community voting mechanism to influence NFT traits.
 * 4. **Staking (VotingPowerStaking):** Stake tokens to gain voting power for trait evolution.
 * 5. **Artist Revenue Sharing (RevenueSharing):** Decentralized distribution of marketplace fees to artists.
 * 6. **Generative Art Engine (GenerativeEngine):** (Conceptual - Could be off-chain or simplified on-chain) Logic to determine initial and evolving traits.
 * 7. **Governance (MarketplaceGovernance):**  DAO-like governance for marketplace parameters.
 * 8. **Treasury (MarketplaceTreasury):**  Management of marketplace revenue and community funds.
 *
 * **Function Summary:**
 *
 * **DynamicArtToken (NFT Functionality):**
 * - `mintDynamicArt(address _to, string memory _baseMetadataURI, bytes32[] memory _initialTraits)`: Mints a new Dynamic Art NFT with initial traits and base metadata URI.
 * - `setBaseMetadataURI(uint256 _tokenId, string memory _baseMetadataURI)`: Sets the base metadata URI for a specific NFT (Owner/Approved).
 * - `getDynamicMetadataURI(uint256 _tokenId)`: Returns the dynamic metadata URI for an NFT, reflecting current traits.
 * - `getTraits(uint256 _tokenId)`: Returns the current traits of an NFT.
 * - `supportsInterface(bytes4 interfaceId)`: ERC721 interface support.
 * - `tokenURI(uint256 tokenId)`: ERC721 token URI (dynamic metadata generation logic).
 * - `approve(address _approved, uint256 _tokenId)`: ERC721 approve.
 * - `transferFrom(address _from, address _to, uint256 _tokenId)`: ERC721 transferFrom.
 * - `safeTransferFrom(address _from, address _to, uint256 _tokenId)`: ERC721 safeTransferFrom.
 * - `setApprovalForAll(address _operator, bool _approved)`: ERC721 setApprovalForAll.
 * - `isApprovedForAll(address _owner, address _operator)`: ERC721 isApprovedForAll.
 * - `ownerOf(uint256 _tokenId)`: ERC721 ownerOf.
 * - `balanceOf(address _owner)`: ERC721 balanceOf.
 * - `totalSupply()`: Returns total supply of NFTs.
 *
 * **ArtMarketplace (Marketplace Functionality):**
 * - `listArt(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the marketplace.
 * - `buyArt(uint256 _tokenId)`: Buys a listed NFT.
 * - `delistArt(uint256 _tokenId)`: Removes an NFT from sale listing.
 * - `startAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration)`: Starts an auction for an NFT.
 * - `bidOnAuction(uint256 _tokenId)`: Places a bid on an active auction.
 * - `endAuction(uint256 _tokenId)`: Ends an auction and transfers NFT to the highest bidder.
 * - `setMarketplaceFee(uint256 _feePercentage)`: Sets the marketplace fee percentage (Governance).
 * - `getListingPrice(uint256 _tokenId)`: Returns the current listing price of an NFT.
 * - `getAuctionDetails(uint256 _tokenId)`: Returns details of an active auction for an NFT.
 *
 * **TraitEvolution (Dynamic Trait Evolution):**
 * - `proposeTraitEvolution(uint256 _tokenId, bytes32[] memory _newTraits)`: Proposes a new set of traits for an NFT (Community).
 * - `voteForEvolution(uint256 _proposalId)`: Votes for a specific trait evolution proposal (Staked Voters).
 * - `executeTraitEvolution(uint256 _proposalId)`: Executes a successful trait evolution proposal (Governance/Admin).
 * - `getEvolutionProposalDetails(uint256 _proposalId)`: Returns details of a trait evolution proposal.
 *
 * **VotingPowerStaking (Staking for Voting):**
 * - `stakeForVotingPower(uint256 _amount)`: Stakes platform tokens to gain voting power.
 * - `unstakeVotingPower(uint256 _amount)`: Unstakes platform tokens and reduces voting power.
 * - `getVotingPower(address _user)`: Returns the current voting power of a user.
 *
 * **RevenueSharing (Artist Revenue Distribution):**
 * - `withdrawArtistRevenue()`: Allows artists to withdraw their accumulated marketplace revenue.
 * - `getArtistRevenueBalance(address _artist)`: Returns the current revenue balance of an artist.
 *
 * **MarketplaceGovernance (Governance - Conceptual):**
 * - `submitGovernanceProposal(string memory _proposalDescription, bytes memory _calldata)`: (Conceptual) Allows submitting governance proposals.
 * - `voteOnGovernanceProposal(uint256 _proposalId, bool _vote)`: (Conceptual) Allows voting on governance proposals.
 * - `executeGovernanceProposal(uint256 _proposalId)`: (Conceptual) Executes a successful governance proposal.
 *
 * **MarketplaceTreasury (Treasury Management - Conceptual):**
 * - `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: (Conceptual) Allows authorized users to withdraw funds from the treasury.
 */

contract DynamicArtMarketplace {
    // --- State Variables ---

    // NFT Contract Instance (Could be separate contract for better modularity in real-world scenario)
    DynamicArtToken public dynamicArtToken;

    // Marketplace Fee (percentage - e.g., 200 for 2%)
    uint256 public marketplaceFeePercentage = 200; // 2% default

    // Marketplace Listings
    struct Listing {
        uint256 price;
        address seller;
        bool isListed;
    }
    mapping(uint256 => Listing) public listings;

    // Auctions
    struct Auction {
        uint256 startingBid;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }
    mapping(uint256 => Auction) public auctions;

    // Trait Evolution Proposals
    struct EvolutionProposal {
        uint256 tokenId;
        bytes32[] newTraits;
        uint256 voteCount;
        bool isActive;
        address proposer;
    }
    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    uint256 public proposalCounter = 0;

    // Voting Power Staking (Simple Example - In real world, use a more robust staking token)
    mapping(address => uint256) public votingPower; // User address => staked amount (voting power)
    uint256 public stakingTokenDecimals = 18; // Assuming staking token has 18 decimals for simplicity

    // Artist Revenue Sharing
    mapping(address => uint256) public artistRevenueBalances; // Artist address => revenue balance

    // Owner of the contract (for admin functions)
    address public owner;

    // --- Events ---
    event ArtListed(uint256 tokenId, uint256 price, address seller);
    event ArtBought(uint256 tokenId, address buyer, uint256 price);
    event ArtDelisted(uint256 tokenId);
    event AuctionStarted(uint256 tokenId, uint256 startingBid, uint256 endTime, address seller);
    event BidPlaced(uint256 tokenId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 tokenId, address winner, uint256 finalPrice);
    event TraitEvolutionProposed(uint256 proposalId, uint256 tokenId, bytes32[] newTraits, address proposer);
    event VoteCast(uint256 proposalId, address voter, uint256 votingPower);
    event TraitEvolutionExecuted(uint256 proposalId, uint256 tokenId, bytes32[] newTraits);
    event StakedForVoting(address user, uint256 amount);
    event UnstakedVoting(address user, uint256 amount);
    event ArtistRevenueWithdrawn(address artist, uint256 amount);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(dynamicArtToken.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier onlyListedArt(uint256 _tokenId) {
        require(listings[_tokenId].isListed, "Art is not listed for sale.");
        _;
    }

    modifier onlyActiveAuction(uint256 _tokenId) {
        require(auctions[_tokenId].isActive, "No active auction for this NFT.");
        _;
    }

    modifier onlyValidProposal(uint256 _proposalId) {
        require(evolutionProposals[_proposalId].isActive, "Invalid or inactive proposal.");
        _;
    }

    // --- Constructor ---
    constructor(address _dynamicArtTokenAddress) {
        owner = msg.sender;
        dynamicArtToken = DynamicArtToken(_dynamicArtTokenAddress);
    }

    // --- Marketplace Functions ---

    /**
     * @dev Sets the marketplace fee percentage. Only callable by the contract owner.
     * @param _feePercentage New marketplace fee percentage (e.g., 200 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    /**
     * @dev Lists an NFT for sale in the marketplace. Only callable by the NFT owner.
     * @param _tokenId ID of the NFT to list.
     * @param _price Sale price in wei.
     */
    function listArt(uint256 _tokenId, uint256 _price) external onlyTokenOwner(_tokenId) {
        require(!listings[_tokenId].isListed, "Art is already listed for sale.");
        require(!auctions[_tokenId].isActive, "Art is currently in auction.");

        listings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isListed: true
        });
        emit ArtListed(_tokenId, _price, msg.sender);
    }

    /**
     * @dev Buys a listed NFT.
     * @param _tokenId ID of the NFT to buy.
     */
    function buyArt(uint256 _tokenId) external payable onlyListedArt(_tokenId) {
        Listing storage listing = listings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy art.");

        uint256 feeAmount = (listing.price * marketplaceFeePercentage) / 10000; // Calculate fee
        uint256 artistShare = feeAmount / 2; // Example: 50% of fee to artist
        uint256 platformShare = feeAmount - artistShare;

        // Transfer funds
        payable(listing.seller).transfer(listing.price - feeAmount); // Seller receives price minus fee
        artistRevenueBalances[dynamicArtToken.artistOf(_tokenId)] += artistShare; // Artist revenue
        payable(owner).transfer(platformShare); // Platform fee to owner (treasury in real world)

        // Transfer NFT
        dynamicArtToken.safeTransferFrom(listing.seller, msg.sender, _tokenId);

        // Update listing
        listing.isListed = false;
        delete listings[_tokenId]; // Remove listing after purchase

        emit ArtBought(_tokenId, msg.sender, listing.price);

        // Return change if any
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
    }

    /**
     * @dev Removes an NFT from the marketplace listing. Only callable by the seller.
     * @param _tokenId ID of the NFT to delist.
     */
    function delistArt(uint256 _tokenId) external onlyTokenOwner(_tokenId) onlyListedArt(_tokenId) {
        Listing storage listing = listings[_tokenId];
        require(listing.seller == msg.sender, "Only the seller can delist the art.");

        listing.isListed = false;
        delete listings[_tokenId]; // Remove listing
        emit ArtDelisted(_tokenId);
    }

    /**
     * @dev Starts an auction for an NFT. Only callable by the NFT owner.
     * @param _tokenId ID of the NFT to auction.
     * @param _startingBid Starting bid amount in wei.
     * @param _auctionDuration Auction duration in seconds.
     */
    function startAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) external onlyTokenOwner(_tokenId) {
        require(!listings[_tokenId].isListed, "Art cannot be auctioned if listed for sale.");
        require(!auctions[_tokenId].isActive, "Auction already active for this NFT.");

        auctions[_tokenId] = Auction({
            startingBid: _startingBid,
            endTime: block.timestamp + _auctionDuration,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });
        emit AuctionStarted(_tokenId, _startingBid, block.timestamp + _auctionDuration, msg.sender);
    }

    /**
     * @dev Places a bid on an active auction.
     * @param _tokenId ID of the NFT being auctioned.
     */
    function bidOnAuction(uint256 _tokenId) external payable onlyActiveAuction(_tokenId) {
        Auction storage auction = auctions[_tokenId];
        require(block.timestamp < auction.endTime, "Auction has ended.");
        require(msg.value > auction.highestBid, "Bid must be higher than the current highest bid.");

        // Refund previous bidder
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        // Update auction
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlaced(_tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Ends an auction and transfers the NFT to the highest bidder.
     * @param _tokenId ID of the NFT to end the auction for.
     */
    function endAuction(uint256 _tokenId) external onlyTokenOwner(_tokenId) onlyActiveAuction(_tokenId) {
        Auction storage auction = auctions[_tokenId];
        require(block.timestamp >= auction.endTime, "Auction is not yet ended.");

        auction.isActive = false;

        uint256 feeAmount = (auction.highestBid * marketplaceFeePercentage) / 10000;
        uint256 artistShare = feeAmount / 2;
        uint256 platformShare = feeAmount - artistShare;

        // Transfer funds
        if (auction.highestBidder != address(0)) {
            payable(dynamicArtToken.ownerOf(_tokenId)).transfer(auction.highestBid - feeAmount); // Seller receives bid minus fee
            artistRevenueBalances[dynamicArtToken.artistOf(_tokenId)] += artistShare; // Artist revenue
            payable(owner).transfer(platformShare); // Platform fee to owner

            // Transfer NFT to highest bidder
            dynamicArtToken.safeTransferFrom(dynamicArtToken.ownerOf(_tokenId), auction.highestBidder, _tokenId);
            emit AuctionEnded(_tokenId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids, return NFT to owner (seller) - no fees
            emit AuctionEnded(_tokenId, address(0), 0); // Indicate no winner
        }

        delete auctions[_tokenId]; // Remove auction data
    }

    /**
     * @dev Gets the listing price of an NFT.
     * @param _tokenId ID of the NFT.
     * @return The listing price in wei, or 0 if not listed.
     */
    function getListingPrice(uint256 _tokenId) external view returns (uint256) {
        return listings[_tokenId].isListed ? listings[_tokenId].price : 0;
    }

    /**
     * @dev Gets details of an active auction for an NFT.
     * @param _tokenId ID of the NFT.
     * @return Auction details (startingBid, endTime, highestBidder, highestBid, isActive).
     */
    function getAuctionDetails(uint256 _tokenId) external view returns (uint256 startingBid, uint256 endTime, address highestBidder, uint256 highestBid, bool isActive) {
        Auction storage auction = auctions[_tokenId];
        return (auction.startingBid, auction.endTime, auction.highestBidder, auction.highestBid, auction.isActive);
    }

    // --- Trait Evolution Functions ---

    /**
     * @dev Proposes a new set of traits for an NFT. Open to community (or based on specific criteria).
     * @param _tokenId ID of the NFT to evolve.
     * @param _newTraits Array of new traits (bytes32).
     */
    function proposeTraitEvolution(uint256 _tokenId, bytes32[] memory _newTraits) external {
        require(!evolutionProposals[proposalCounter].isActive, "Previous proposal is still active."); // Simple sequential proposal ID

        evolutionProposals[proposalCounter] = EvolutionProposal({
            tokenId: _tokenId,
            newTraits: _newTraits,
            voteCount: 0,
            isActive: true,
            proposer: msg.sender
        });
        emit TraitEvolutionProposed(proposalCounter, _tokenId, _newTraits, msg.sender);
        proposalCounter++;
    }

    /**
     * @dev Votes for a specific trait evolution proposal. Requires staked voting power.
     * @param _proposalId ID of the evolution proposal.
     */
    function voteForEvolution(uint256 _proposalId) external onlyValidProposal(_proposalId) {
        require(votingPower[msg.sender] > 0, "You need voting power to vote.");

        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        require(proposal.isActive, "Proposal is not active.");

        proposal.voteCount += getVotingPower(msg.sender); // Vote power based on staking
        emit VoteCast(_proposalId, msg.sender, getVotingPower(msg.sender));
    }

    /**
     * @dev Executes a successful trait evolution proposal. Can be triggered by governance or admin after vote threshold reached.
     * @param _proposalId ID of the evolution proposal to execute.
     */
    function executeTraitEvolution(uint256 _proposalId) external onlyOwner onlyValidProposal(_proposalId) { // Example: Only owner can execute after voting
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        require(proposal.isActive, "Proposal is not active.");
        require(proposal.voteCount > 50, "Proposal does not have enough votes."); // Example: > 50 votes needed

        dynamicArtToken.setTraits(proposal.tokenId, proposal.newTraits); // Update NFT traits in token contract
        proposal.isActive = false; // Mark proposal as executed

        emit TraitEvolutionExecuted(_proposalId, proposal.tokenId, proposal.newTraits);
    }

    /**
     * @dev Gets details of a trait evolution proposal.
     * @param _proposalId ID of the evolution proposal.
     * @return Proposal details (tokenId, newTraits, voteCount, isActive, proposer).
     */
    function getEvolutionProposalDetails(uint256 _proposalId) external view returns (uint256 tokenId, bytes32[] memory newTraits, uint256 voteCount, bool isActive, address proposer) {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        return (proposal.tokenId, proposal.newTraits, proposal.voteCount, proposal.isActive, proposal.proposer);
    }

    // --- Voting Power Staking Functions ---

    /**
     * @dev Stakes platform tokens to gain voting power. (Simplified - In real world, use a proper staking token/contract).
     * @param _amount Amount of platform tokens to stake (in staking token's base units).
     */
    function stakeForVotingPower(uint256 _amount) external {
        // In a real scenario, you would interact with a separate staking token contract here.
        // For this example, we directly update votingPower (assuming simplified staking).
        votingPower[msg.sender] += _amount; // Increase voting power
        emit StakedForVoting(msg.sender, _amount);
    }

    /**
     * @dev Unstakes platform tokens and reduces voting power.
     * @param _amount Amount of platform tokens to unstake.
     */
    function unstakeVotingPower(uint256 _amount) external {
        require(votingPower[msg.sender] >= _amount, "Insufficient staked amount.");
        votingPower[msg.sender] -= _amount; // Decrease voting power
        emit UnstakedVoting(msg.sender, _amount);
    }

    /**
     * @dev Gets the current voting power of a user.
     * @param _user Address of the user.
     * @return The voting power of the user.
     */
    function getVotingPower(address _user) public view returns (uint256) {
        return votingPower[_user];
    }

    // --- Artist Revenue Sharing Functions ---

    /**
     * @dev Allows artists to withdraw their accumulated marketplace revenue.
     */
    function withdrawArtistRevenue() external {
        uint256 balance = artistRevenueBalances[msg.sender];
        require(balance > 0, "No revenue balance to withdraw.");

        artistRevenueBalances[msg.sender] = 0; // Reset balance
        payable(msg.sender).transfer(balance);
        emit ArtistRevenueWithdrawn(msg.sender, balance);
    }

    /**
     * @dev Gets the current revenue balance of an artist.
     * @param _artist Address of the artist.
     * @return The revenue balance of the artist.
     */
    function getArtistRevenueBalance(address _artist) external view returns (uint256) {
        return artistRevenueBalances[_artist];
    }

    // --- Fallback and Receive Functions ---
    receive() external payable {} // To receive ETH for buying art and auctions

    fallback() external {}
}


// --- DynamicArtToken Contract (Separate contract for better organization in real-world scenario) ---
contract DynamicArtToken {
    string public name = "Dynamic Art Token";
    string public symbol = "DAT";

    // Base Metadata URI (can be set per token)
    mapping(uint256 => string) public baseMetadataURIs;

    // Generative Traits (bytes32 array per token)
    mapping(uint256 => bytes32[]) public tokenTraits;

    // Artist mapping for revenue sharing
    mapping(uint256 => address) public tokenArtists;

    // Token Counter
    uint256 public tokenCounter = 0;

    // ERC721 Standard Mappings
    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // --- Events ---
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event DynamicArtMinted(uint256 tokenId, address artist, string baseMetadataURI, bytes32[] initialTraits);
    event TraitsUpdated(uint256 tokenId, bytes32[] newTraits);
    event BaseMetadataURISet(uint256 tokenId, string baseMetadataURI);

    // --- Constructor ---
    constructor() {
        // Initialize any necessary state
    }

    // --- Minting Function ---
    /**
     * @dev Mints a new Dynamic Art NFT. Only callable by authorized minter (e.g., Marketplace contract).
     * @param _to Address to mint the NFT to.
     * @param _baseMetadataURI Base URI for metadata (e.g., IPFS hash prefix).
     * @param _initialTraits Array of initial generative traits (bytes32).
     */
    function mintDynamicArt(address _to, string memory _baseMetadataURI, bytes32[] memory _initialTraits) external { // In real world, restrict access to a minter role/contract
        require(_to != address(0), "Mint to the zero address");

        uint256 newTokenId = tokenCounter++;
        _ownerOf[newTokenId] = _to;
        _balanceOf[_to]++;
        baseMetadataURIs[newTokenId] = _baseMetadataURI;
        tokenTraits[newTokenId] = _initialTraits;
        tokenArtists[newTokenId] = msg.sender; // Example: Minter is considered artist initially

        emit Transfer(address(0), _to, newTokenId);
        emit DynamicArtMinted(newTokenId, msg.sender, _baseMetadataURI, _initialTraits);
    }

    /**
     * @dev Sets the base metadata URI for a specific NFT. Only owner or approved.
     * @param _tokenId ID of the NFT.
     * @param _baseMetadataURI New base metadata URI.
     */
    function setBaseMetadataURI(uint256 _tokenId, string memory _baseMetadataURI) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved or owner");
        baseMetadataURIs[_tokenId] = _baseMetadataURI;
        emit BaseMetadataURISet(_tokenId, _baseMetadataURI);
    }

    /**
     * @dev Sets the traits for a specific NFT. Only callable by authorized contract (e.g., TraitEvolution).
     * @param _tokenId ID of the NFT.
     * @param _newTraits Array of new traits (bytes32).
     */
    function setTraits(uint256 _tokenId, bytes32[] memory _newTraits) external { // Restrict access to authorized contracts only in real scenario
        tokenTraits[_tokenId] = _newTraits;
        emit TraitsUpdated(_tokenId, _newTraits);
    }

    /**
     * @dev Returns the current traits of an NFT.
     * @param _tokenId ID of the NFT.
     * @return Array of traits (bytes32).
     */
    function getTraits(uint256 _tokenId) external view returns (bytes32[] memory) {
        return tokenTraits[_tokenId];
    }

    /**
     * @dev Returns the artist address associated with an NFT.
     * @param _tokenId ID of the NFT.
     * @return Artist address.
     */
    function artistOf(uint256 _tokenId) external view returns (address) {
        return tokenArtists[_tokenId];
    }

    /**
     * @dev Generates the dynamic metadata URI for an NFT based on its current traits.
     * @param _tokenId ID of the NFT.
     * @return The dynamic metadata URI.
     */
    function getDynamicMetadataURI(uint256 _tokenId) public view returns (string memory) {
        string memory baseURI = baseMetadataURIs[_tokenId];
        bytes32[] memory currentTraits = tokenTraits[_tokenId];

        // **Conceptual Dynamic Metadata Generation Logic (Replace with actual logic):**
        // In a real application, this logic would be more complex and potentially involve:
        // 1. Off-chain rendering based on traits (e.g., using IPFS and a generative art engine).
        // 2. On-chain SVG generation (more gas intensive, but fully decentralized).
        // 3. Returning a JSON metadata object directly (less dynamic URI, but simpler).

        string memory traitsString = "";
        for (uint256 i = 0; i < currentTraits.length; i++) {
            traitsString = string(abi.encodePacked(traitsString, bytes32ToString(currentTraits[i]))); // Simple trait concatenation
            if (i < currentTraits.length - 1) {
                traitsString = string(abi.encodePacked(traitsString, "-")); // Separator
            }
        }

        return string(abi.encodePacked(baseURI, _toString(_tokenId), "-", traitsString, ".json")); // Example: IPFS://baseURI/{tokenId}-{traits}.json
    }

    // --- ERC721 Standard Functions ---

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Balance query for the zero address");
        return _balanceOf[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = _ownerOf[_tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address _approved, uint256 _tokenId) public payable {
        address tokenOwner = ownerOf(_tokenId);
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {
        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable {
        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(address(0), _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return getDynamicMetadataURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x80ac58cd || // ERC721Metadata
               interfaceId == 0x5b5e139f;   // ERC721
    }

    function totalSupply() public view returns (uint256) {
        return tokenCounter;
    }

    // --- Internal Helper Functions ---

    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _ownerOf[_tokenId] != address(0);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(_tokenId);
        return (_spender == tokenOwner || getApproved(_tokenId) == _spender || isApprovedForAll(tokenOwner, _spender));
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), _tokenId); // Clear approvals
        _balanceOf[_from]--;
        _balanceOf[_to]++;
        _ownerOf[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function _approve(address _approved, uint256 _tokenId) internal {
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }

    function _checkOnERC721Received(address _operator, address _to, uint256 _tokenId, bytes memory _data) private returns (bool) {
        if (!_isContract(_to)) {
            return true;
        }
        bytes4 returnData = IERC721Receiver(_to).onERC721Received(_operator, address(0), _tokenId, _data);
        return returnData == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // --- Utility Functions ---
    function _toString(uint256 value) internal pure returns (string memory) {
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

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory byteString = new bytes(32);
        uint256 len = 0;
        for (uint256 i = 0; i < 32; i++) {
            bytes1 char = bytes1(bytes32(_bytes32 << (i * 8)));
            if (char != 0) {
                byteString[len++] = char;
            }
        }
        bytes memory resizedByteString = new bytes(len);
        for (uint256 j = 0; j < len; j++) {
            resizedByteString[j] = byteString[j];
        }
        return string(resizedByteString);
    }
}

interface IERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}
```